# -*- mode: ruby -*-
# Script for ingesting items into Merritt by parsing an Atom feed.
#
# Author::    Erik Hetzner (mailto:erik.hetzner@ucop.edu)
# Copyright:: Copyright (c) 2011 Regents of the University of California

# TODO: write tests for this, then remove it from exclude list in top-level .rubocop.yml

require 'tmpdir'
require 'fileutils'
require 'open-uri'
require 'mrt/ingest'

OPEN_URI_ARGS = {"User-Agent" => "Ruby/#{RUBY_VERSION}"}

# Namespaces
NS = { "atom"  => "http://www.w3.org/2005/Atom",
       "xhtml" => "http://www.w3.org/1999/xhtml" }

DELAY = 300
BATCH_SIZE = 10

# RESTART_SERVER = 10

def xpath_content(node, xpath)
  nodes = node.xpath(xpath, NS)
  return nil if (nodes.nil? || nodes.size == 0)
  return nodes[0].content
end

def up_to_date?(local_id, collection_id, updated, feeddate)

  updated_date = DateTime.parse(updated)
  feeddate_date = DateTime.parse(feeddate)

  # Has feed been updated since our last run?
  if ! updated.nil? && ! feeddate.nil? && local_id.nil? && collection_id.nil? then
    if feeddate_date >= updated_date then
      puts "No update in feed since last run"
      puts "Exiting: #{feeddate_date} >= #{updated_date}"
      return true
    else
      return false
    end
  end

  obj = InvObject.joins(:inv_collections).where(["erc_where LIKE ?", "%#{local_id}%"]).where(:inv_collections => { :ark => collection_id})

  if obj.empty? then
    return false
  else
    if updated.nil? then
      return false
    else
      submit = updated_date <= obj.first.modified
      if (! submit) then
        puts "Updating #{local_id}"
        puts "         #{updated_date} > #{obj.first.modified}"
      else
        puts "NO need to update: #{local_id}"
        puts "                   #{updated_date} <= #{obj.first.modified}"
      end
      return submit
    end
  end
end

def process_atom_feed(submitter, profile, collection, feeddatefile, starting_point)
  client = Mrt::Ingest::Client.new(APP_CONFIG['ingest_service'])
  server = Mrt::Ingest::OneTimeServer.new
  server.start_server
  next_page = starting_point	# page feed processing
  # i = 0
  pause = ENV['HOME'] + "/dpr2/apps/ui/atom/PAUSE_ATOM_#{profile}"
  lastFeedUpdate = false

  until next_page.nil? do
    wait = false

    while (File.exist?(pause)) do
      # pause
      puts "Processed paused: #{pause}"
      sleep(DELAY)
    end

    for j in 0..2
      begin
        p = open(next_page, OPEN_URI_ARGS)
        if (p.status.first == "404")
          puts "Page not found, exiting... #{next_page}"
          return
        end
        doc = Nokogiri::XML(p)
        break
      rescue Exception=>ex
        puts ex.message
        puts ex.backtrace
        puts "Error processing page #{next_page}"
      end
    end

    # Has feed been updated?
    feedUpdated = doc.at_xpath("//xmlns:updated").text
    if File.exists?(feeddatefile)
      feeddate = `cat #{feeddatefile}`
    else
      puts "Feed date file does not exist: #{feeddatefile}"
      return nil
    end
    lastFeedUpdate = up_to_date?(nil, nil, feedUpdated, feeddate)
    if lastFeedUpdate then
      puts "Feed has not been modified since last run.  Exiting..."
      return
    end

    # Merritt Collection (optional)
    begin
      merrittCollection = doc.at_xpath("//xmlns:merritt_collection_id").text
      merrittCollectionCredentials = ATOM_CONFIG["#{merrittCollection}_credentials"]
      merrittCollectionLocalidElement = ATOM_CONFIG["#{merrittCollection}_localidElement"]
      # merrittCollectionLastFeedUpdatedFile = ATOM_CONFIG["#{merrittCollection}_lastFeedUpdate"]
      merrittCollectionLastFeedUpdatedFile = feeddatefile
      if (merrittCollectionLocalidElement.empty) then
        merrittCollectionLocalidElement.empty = "atom:id"     # default
      end
    rescue Exception => ex
    end
    puts "Processing merritt collection #{merrittCollection}" if ! merrittCollection.nil?
    puts "Found merritt collection credentials" if ! merrittCollectionCredentials.nil?
    puts "Found merritt collection localID element #{merrittCollectionLocalidElement}" if ! merrittCollectionLocalidElement.nil?

    onum = 0
    doc.xpath("//atom:entry", NS).each do |entry|
      begin
        # get the basic stuff
        published = xpath_content(entry, "atom:published")
        updated = xpath_content(entry, "atom:updated")
        title = xpath_content(entry, "atom:title")

        # DC metadata
        begin
          local_id = entry.at_xpath("#{merrittCollectionLocalidElement}").text
        rescue Exception => ex
          # ex.backtrace
        end
        begin
          dc_title = entry.at_xpath("dc:title").text
        rescue Exception => ex
          dc_title = nil
        end
        begin
          dc_date = entry.at_xpath("dc:date").text
        rescue Exception => ex
          dc_date = nil
        end
        begin
          dc_creator = entry.at_xpath("dc:creator").text
        rescue Exception => ex
          dc_creator = nil
        end
        creator = entry.xpath("atom:author", NS).map { |au|
          xpath_content(au, "atom:name")
        }.join("; ")

        puts "Processing local_id:	#{local_id}"
        puts "Processing Title:		" + (dc_title || title)
        puts "Processing Date:		" + (dc_date || published)
        puts "Processing Creator:	" + (dc_creator || creator)
        puts "Processing Updated:	#{updated}"
        p =  up_to_date?(local_id, collection, updated, feeddate)
        return if p.nil?

        # No need to process this record
        next if p

        # Add second localid if present
        begin
          local_id2 = entry.at_xpath("nx:identifier").text
          puts "Processing additional local_id:	#{local_id2}"
        rescue Exception => ex
          # ex.backtrace
        end
        local_id.concat("; ", local_id2) if !local_id2.nil?

        wait = true

        # pull out the urls
        urls = entry.xpath("atom:link", NS).map do |link|
          { :rel  => link['rel'],
            :url  => link['href'],
            :checksum  => link.xpath('.//opensearch:checksum'),
            :name => link['href'].sub(/^https?:\/\//, '') }
        end

        # extract the archival id, if it exists
        archival_id = urls.select {|u|
          (u[:rel] == 'archival')
        }.first

        # do not submit archival link
        urls = urls.delete_if {|u| u[:rel] == 'archival'}

        erc = {
          "who" => (dc_creator || creator),
          "what" => (dc_title || title),
          "when" => (dc_date || published),
          "where" => archival_id,
          "when/created" => published,
          "when/modified" => updated }
        iobject = Mrt::Ingest::IObject.new(:erc              => erc,
                                           :server           => server,
                                           :local_identifier => local_id,
                                           :archival_id      => archival_id)

        # add componenets
        urls.each do |url|
          obj = URI.parse(URI.encode(url[:url]).gsub("[","%5B").gsub("]","%5D"))

          # Basic auth
          if (obj.host.include? "nuxeo.cdlib.org") then
            puts "Using basic authentication: #{url[:url]}"
            obj.user = merrittCollectionCredentials.split(':')[0]
            obj.password = merrittCollectionCredentials.split(':')[1]
          end

          # extract checksum if available
          if not url[:checksum].empty? then
            # alg = url[:checksum].last['algorithm']
            # checksum = url[:checksum].last.text
            checksum = Mrt::Ingest::MessageDigest::MD5.new(url[:checksum].last.text)
          else
            checksum = nil
          end

          iobject.add_component(obj,
                                :name=>url[:name],
                                :prefetch=>true,
                                :digest=>checksum,
                                # workaround for funky site
                                :prefetch_options=>{"Accept"=>"text/html, */*"})
        end
        resp = iobject.start_ingest(client, profile, submitter)
          # puts "User Agent: #{resp.user_agent}"
          # puts "Batch ID: #{resp.batch_id}"
          # puts "Submission Date: #{resp.submission_date}"
      rescue Exception=>ex
        puts ex.message
        puts ex.backtrace
        local_id = xpath_content(entry, "atom:id")
        puts "Exception processing #{local_id} from #{next_page}."
      end
      onum = onum + 1

      if (onum % BATCH_SIZE == 0) then
        puts "Total entries processed: #{onum}"
        sleep(DELAY)
      end
    end
    #i = i + 1
    # break if (i > 20)
    #if ( i % RESTART_SERVER == 0 ) then
    #begin
    #puts "Restarting server after iteration: #{i}"
    #server.join_server
    #rescue
    #end
    #server.stop_server
    #server = Mrt::Ingest::OneTimeServer.new
    #server.start_server
    #end

    current_page = next_page
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")

    if (! next_page.nil?) then
      if (current_page == next_page || next_page.empty)
        puts "No page processing or no new page."
        next_page = nil
      else
        puts "Next page: #{next_page}"
      end
    else
      puts "No paging element found."
    end

    if (wait) then
      # sleep(DELAY)
    else
      sleep(5)	    # process quickly
    end
  end
ensure
  if ! lastFeedUpdate then
    puts "Updating file: #{merrittCollectionLastFeedUpdatedFile}"
    puts "Updating feed date to: #{feedUpdated}"
    begin
      file = File.open("#{merrittCollectionLastFeedUpdatedFile}", "w")
      file.write("#{feedUpdated}")
    rescue IOError => e
    ensure
      file.close unless file.nil?
    end
  end
  puts "Waiting for processing to finish"
  begin
    server.join_server
  rescue
  end
end

# call as rake "atom:update[atom URL, User Agent, Ingest Profile, Collection ID, Feed last update]"
# e.g. rake "atom:update[http://opencontext.org/all/.atom, mreyes/Mark Reyes, ucb_open_context_content, ark:/99999/abcdefhi, <DATE>]"
namespace :atom do
  desc "Generic ATOM to Merritt processor"
  task :update, [:root, :user, :profile, :collection, :feeddatefile] => :environment do |cmd, args|
    # TODO: normalize task arg / function parameter names, use named parameters for function
    process_atom_feed(args[:user], args[:profile], args[:collection], args[:feeddatefile], args[:root])
  end
end
