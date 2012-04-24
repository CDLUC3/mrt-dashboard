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

def up_to_date?(store, local_id, last_updated)
  q = Mrt::Sparql::Q.new("?s object:localIdentifier \"#{local_id}\"")
  res = store.select(q)
  if res.empty? then
    return false
  else
    obj = MrtObject.new(res[0]['s'])
    if last_updated.nil? then
      return false 
    else
      last_updated_date = DateTime.parse(last_updated)
      return last_updated_date >= obj.modified
    end
  end
end

def process_atom_feed(submitter, profile, starting_point)
  store = Mrt::Sparql::Store.new(SPARQL_ENDPOINT)
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

        next if up_to_date? (store, local_id, updated)

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
    break if (i > 20)
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")
    sleep(PAGE_DELAY)
  end
  server.join_server
end

# call as rake "atom:update[http://opencontext.org/all/.atom, egh/Erik Hetzner, ucb_open_context_content]"
namespace :atom do
  task :update, [:root, :user, :profile] => :environment do |cmd, args|
    process_atom_feed(args[:user], args[:profile], args[:root])
  end
end
