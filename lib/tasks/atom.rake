# -*- mode: ruby -*-
# Script for ingesting items into Merritt by parsing an Atom feed.
#
# Author::    Erik Hetzner (mailto:erik.hetzner@ucop.edu)
# Copyright:: Copyright (c) 2011 Regents of the University of California

require 'tmpdir'
require 'fileutils'
require 'open-uri'
require 'mrt/ingest'

OPEN_URI_ARGS = {"User-Agent" => "Ruby/#{RUBY_VERSION}"}

# Namespaces
NS = { "atom"  => "http://www.w3.org/2005/Atom",
       "xhtml" => "http://www.w3.org/1999/xhtml" }

DELAY = 15
BATCH_SIZE = 10	

RESTART_SERVER = 10

def xpath_content(node, xpath)
  nodes = node.xpath(xpath, NS)
  return nil if (nodes.nil? || nodes.size == 0)
  return nodes[0].content
end

# augment to include terminate processing info [mjr]
def up_to_date?(local_id, collection_id, last_updated, stopdate)
  obj = InvObject.joins(:inv_collections).where(["erc_where LIKE ?", "%#{local_id}%"]).where(:inv_collections => { :ark => collection_id})

  # terminate processing?
  if ! last_updated.nil? && ! stopdate.nil?  then
    last_updated_date = DateTime.parse(last_updated)
    stopdate_date = DateTime.parse(stopdate)

    if stopdate_date >= last_updated_date then
      puts "Exiting: #{stopdate_date} > #{last_updated_date}"
      return nil
    end
  end

  if obj.empty? then
    return false
  else
    if last_updated.nil? then
      return false 
    else
      last_updated_date = DateTime.parse(last_updated)
      updated = last_updated_date <= obj.first.modified
      if (! updated) then
	puts "Updating #{local_id}"
	puts "         #{last_updated_date} > #{obj.first.modified}"
      else
	puts "NO need to update: #{local_id}"
	puts "                   #{last_updated_date} <= #{obj.first.modified}"
      end
      return updated
    end
  end
end

def process_atom_feed(submitter, profile, collection, stopdate, starting_point)
  client = Mrt::Ingest::Client.new(APP_CONFIG['ingest_service'])
  server = Mrt::Ingest::OneTimeServer.new
  server.start_server
  next_page = starting_point	# page feed processing
  i = 0
  pause = ENV['HOME'] + "/apps/ui/atom/PAUSE_ATOM_#{profile}"

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

    # Merritt Collection (optional)
    begin
       merrittCollection = doc.at_xpath("//xmlns:merritt_collection_id").text
       merrittCollectionCredentials = ATOM_CONFIG["#{merrittCollection}_credentials"]
       merrittCollectionLocalidElement = ATOM_CONFIG["#{merrittCollection}_localidElement"]
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
        begin
           local_id = entry.at_xpath("#{merrittCollectionLocalidElement}").text 
        rescue Exception => ex
           ex.backtrace
        end
        # get the basic stuff
        published = xpath_content(entry, "atom:published")
        updated = xpath_content(entry, "atom:updated")
        title = xpath_content(entry, "atom:title")
        creator = entry.xpath("atom:author", NS).map { |au|
          xpath_content(au, "atom:name")
        }.join("; ")

	puts "Processing local_id: #{local_id}"
	puts "Processing Title:    #{title}"
	puts "Processing updated:  #{updated}"
        p =  up_to_date?(local_id, collection, updated, stopdate)

        return if p.nil? 

	# advance to next
        next if p

	wait = true

        # pull out the urls
        urls = entry.xpath("atom:link", NS).map do |link| 
          { :rel  => link['rel'], 
            :url  => link['href'],
            :name => link['href'].sub(/^https?:\/\//, '') }
        end

        # extract the archival id, if it exists
        archival_id = urls.select {|u|
          (u[:rel] == 'archival')
        }.first 

        # do not submit archival link
        urls = urls.delete_if {|u| u[:rel] == 'archival'}

        erc = {
          "who" => creator,
          "what" => title,
          "when" => published,
          "where" => (archival_id || local_id),
          "when/created" => published,
          "when/modified" => updated }
        iobject = Mrt::Ingest::IObject.new(:erc         => erc,
                                           :server      => server,
                                           :archival_id => archival_id)

        # add componenets
        urls.each do |url|
          obj = URI.parse(url[:url])

	  # Basic auth 
	  if (obj.path.include? "Nuxeo") then
	    puts "Using basic authentication: #{url[:url]}"
            obj.user = merrittCollectionCredentials.split(':')[0]
            obj.password = merrittCollectionCredentials.split(':')[1]
	  end 

          iobject.add_component(obj,
		  :name=>url[:name], 
                  :prefetch=>true,
                  # workaround for funky site
                  :prefetch_options=>{"Accept"=>"text/html, */*"})
        end
        resp = iobject.start_ingest(client, profile, submitter)
	puts "User Agent: #{resp.user_agent}"
	puts "Batch ID: #{resp.batch_id}"
	puts "Submission Date: #{resp.submission_date}"
      rescue Exception=>ex
	puts ex.message
	puts ex.backtrace
        local_id = xpath_content(entry, "atom:id")
        puts "Exception processing #{local_id} from #{next_page}."
      end
      onum = onum + 1

      if (onum % BATCH_SIZE == 0) 
	puts "Total entries processed: #{onum}"
	sleep(PAGE_DELAY)
      end
    end
    i = i + 1
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
      # sleep(PAGE_DELAY)
    else 
      sleep(5)	    # process quickly
    end
  end
  ensure
    puts "Waiting for processing to finish"
    begin
      server.join_server
    rescue
    end
end

# call as rake "atom:update[atom URL, User Agent, Ingest Profile, Collection ID, Process until Date]"
# e.g. rake "atom:update[http://opencontext.org/all/.atom, mreyes/Mark Reyes, ucb_open_context_content, ark:/99999/abcdefhi, <DATE>]"
namespace :atom do
  desc "Generic ATOM to Merritt processor"
  task :update, [:root, :user, :profile, :collection, :stopdate] => :environment do |cmd, args|
    process_atom_feed(args[:user], args[:profile], args[:collection], args[:stopdate], args[:root])
  end
end
