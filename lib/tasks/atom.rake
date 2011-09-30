# -*- mode: ruby -*-
# Script for ingesting items into Merritt by parsing an Atom feed.
#
# Author::    Erik Hetzner (mailto:erik.hetzner@ucop.edu)
# Copyright:: Copyright (c) 2011 Regents of the University of California

require 'tmpdir'
require 'fileutils'
require 'open-uri'

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

def ingest(submitter, profile, creator, title, date, local_id, primary_id, file)
  params = {
    'file'              => file,
    'type'              => "object-manifest",
    'submitter'         => submitter,
    'filename'          => file.path.split(/\//).last,
    'primaryIdentifier' => primary_id,
    'profile'           => profile,
    'responseForm'      => 'xml' }.
    delete_if {|k,v| v.nil? }
  response = RestClient.post(INGEST_SERVICE, params, { :multipart => true })
  @doc = Nokogiri::XML(response) do |config|
    config.strict.noent.noblanks
  end
end

# Create & return a manifest file. Takes an array of pairs, [[url1,
# filename1], ...]
def mk_manifest(manifest, urls)
  manifest.write("#%checkm_0.7\n")
  manifest.write("#%profile http://uc3.cdlib.org/registry/ingest/manifest/mrt-ingest-manifest\n")
  manifest.write("#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom#\n")
  manifest.write("#%prefix | nfo: | http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#\n")
  manifest.write("#%fields | nfo:fileUrl | nfo:hashAlgorithm | nfo:hashValue | nfo:fileSize | nfo:fileLastModified | nfo:fileName | mrt:mimeType\n")
  urls.each do |url|
    manifest.write("#{url['url']} | | | | | #{url['name']} |\n")
  end
  manifest.write("#%EOF\n")
end

# Create ERC file.
def mk_erc(erc, creator, title, date, identifier, created, modified)
  erc.write("who: #{creator}\n")
  erc.write("what: #{title}\n")
  erc.write("when: #{date}\n")
  erc.write("where: #{identifier}\n")
  erc.write("when/created: #{created}\n")
  erc.write("when/modified: #{modified}\n")
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

def process_atom_feed(server, submitter, profile, starting_point)
  next_page = starting_point
  n = 0
  until next_page.nil? do
    doc = Nokogiri::XML(open(next_page, OPEN_URI_ARGS))
    doc.xpath("//atom:entry", NS).each do |entry|
      # get the basic stuff
      local_id = xpath_content(entry, "atom:id")
      modified = xpath_content(entry, "atom:updated")
      date = xpath_content(entry, "atom:published")
      title = xpath_content(entry, "atom:title")
      creator = entry.xpath("atom:author", NS).map { |au|
        xpath_content(au, "atom:name")
      }.join("; ")
      urls = entry.xpath("atom:link", NS).map do |link| 
        { 'rel'  => link['rel'], 
          'url'  => link['href'],
          'name' => link['href'].sub(/^https?:\/\//, '') }
      end

      # extract the archival id, if it exists
      archival_id = urls.select {|u|
        (u['rel'] == 'archival')
      }.map {|u| 
        # extract url only, and remove extra junk
        u['url'].sub(/ezid\/id\//, '')
      }.first 

      # do not submit archival link
      urls = urls.delete_if {|u| u['rel'] == 'archival'}

      # Make mrt-erc.txt file & add to list of urls to ingest
      erc_url = server.add_file do |erc|
        mk_erc(erc, creator, title, date, (archival_id || local_id), date, modified)
      end
      urls.push({ 'rel'  => 'metadata',
                  'url'  => erc_url, 
                  'name' => 'mrt-erc.txt'})

      # Make manifest file.
      manifest_file = Tempfile.new("mrt-atom-ingester")
      mk_manifest(manifest_file, urls)
      # reset to beginning
      manifest_file.open
      
      ingest(submitter, profile, creator, title, date, local_id, archival_id, manifest_file)
      break
    end
    break
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")
    sleep(PAGE_DELAY)
  end
end

# call as rake "atom:update[http://opencontext.org/all/.atom, egh/Erik Hetzner, ucb_open_context_content]"
namespace :atom do
  task :update, :root, :user, :profile, :needs => :environment do |cmd, args|
    server = Mrt::OneTimeServer.new
    process_atom_feed(server, args[:user], args[:profile], args[:root])
    # Run server and wait until ingest is finished.
    server.run
  end
end
