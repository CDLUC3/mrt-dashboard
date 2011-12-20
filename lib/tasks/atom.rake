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
  end
end

def process_atom_feed(submitter, profile, starting_point)
  client = Mrt::Ingest::Client.new(INGEST_SERVICE)
  next_page = starting_point
  n = 0
  until next_page.nil? do
    doc = Nokogiri::XML(open(next_page, OPEN_URI_ARGS))
    doc.xpath("//atom:entry", NS).each do |entry|
      # get the basic stuff
      local_id = xpath_content(entry, "atom:id")
      published = xpath_content(entry, "atom:published")
      title = xpath_content(entry, "atom:title")
      creator = entry.xpath("atom:author", NS).map { |au|
        xpath_content(au, "atom:name")
      }.join("; ")

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
        "when/modified" => xpath_content(entry, "atom:updated") }
      iobject = Mrt::Ingest::IObject.new(:erc         => erc,
                                         :archival_id => archival_id)

      # add componenets
      urls.each do |url|
        iobject.add_component(URI.parse(url[:url]), url[:name])
      end
#      iobject.start_ingest(client, profile, submitter)
#      iobject.finish_ingest()
    end
    return
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")
    sleep(PAGE_DELAY)
  end
end

# call as rake "atom:update[http://opencontext.org/all/.atom, egh/Erik Hetzner, ucb_open_context_content]"
namespace :atom do
  task :update, [:root, :user, :profile] => :environment do |cmd, args|
    process_atom_feed(args[:user], args[:profile], args[:root])
  end
end
