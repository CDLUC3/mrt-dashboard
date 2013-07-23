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

PAGE_DELAY = 10 # delay between each page we process

def xpath_content(node, xpath)
  nodes = node.xpath(xpath, NS)
  return nil if (nodes.nil? || nodes.size == 0)
  return nodes[0].content
end

# augment to include terminate processing info [mjr]
def up_to_date?(local_id, collection_id, last_updated, stopdate)
  obj = MrtObject.joins(:mrt_collections).where(["local_id = ?", local_id]).where(:mrt_collections => { :ark => collection})

  # terminate processing?
  if ! stopdate.nil? && ! stopdate.nil?  then
    last_updated_date = DateTime.parse(last_updated)
    stopdate_date = DateTime.parse(stopdate)

    puts "last update: #{last_updated_date}"
    puts "stop: #{stopdate_date}"
    if last_updated_date >= stopdate_date then
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
      return last_updated_date >= obj.first.last_add_version
    end
  end
end

def process_atom_feed(submitter, profile, collection, stopdate, starting_point)
  client = Mrt::Ingest::Client.new(INGEST_SERVICE)
  server = Mrt::Ingest::OneTimeServer.new
  server.start_server
  next_page = starting_point
  i = 0
  until next_page.nil? do
    doc = Nokogiri::XML(open(next_page, OPEN_URI_ARGS))
    doc.xpath("//atom:entry", NS).each do |entry|
      begin
        # get the basic stuff
        local_id = xpath_content(entry, "atom:id")
        published = xpath_content(entry, "atom:published")
        updated = xpath_content(entry, "atom:updated")
        title = xpath_content(entry, "atom:title")
        creator = entry.xpath("atom:author", NS).map { |au|
          xpath_content(au, "atom:name")
        }.join("; ")

        p =  up_to_date?(local_id, collection, updated, stopdate)
	break if p.nil?
        next if p?

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
          iobject.add_component(URI.parse(url[:url]), 
                                :name=>url[:name], 
                                :prefetch=>true,
                                # workaround for funky site
                                :prefetch_options=>{"Accept"=>"text/html, */*"})
        end
        iobject.start_ingest(client, profile, submitter)
      rescue Exception=>ex
        local_id = xpath_content(entry, "atom:id")
        puts "Exception processing #{local_id} from #{next_page}."
      end
    end
    i = i + 1
    # break if (i > 20)
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")
    sleep(PAGE_DELAY)
  end
  server.join_server
end

# call as rake "atom:update[atom URL, User Agent, Ingest Profile, Collection ID, Process until Date]"
# e.g. rake "atom:update[http://opencontext.org/all/.atom, mreyes/Mark Reyes, ucb_open_context_content, ark:/99999/abcdefhi, <DATE>]"
namespace :atom do
  task :update, [:root, :user, :profile, :collection, :stopdate] => :environment do |cmd, args|
    process_atom_feed(args[:user], args[:profile], args[:collection], args[:stopdate], args[:root])
  end
end
