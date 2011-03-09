# Script for ingesting items into Merritt by parsing an Atom feed.
#
# Author::    Erik Hetzner (mailto:erik.hetzner@ucop.edu)
# Copyright:: Copyright (c) 2011 Regents of the University of California

# Namespaces
NS = { "atom"  => "http://www.w3.org/2005/Atom",
       "xhtml" => "http://www.w3.org/1999/xhtml" }

def xpath_content(node, xpath)
  nodes = node.xpath(xpath, NS)
  return nil if (nodes.nil? || nodes.size == 0)
  return nodes[0].content
end

def ingest(submitter, profile, creator, title, date, local_id, file)
  params = {
    'file'              => file,
    'type'              => "object-manifest",
    'submitter'         => submitter,
    'filename'          => file.path.split(/\//).last,
    'profile'           => profile,
    'creator'           => creator,
    'title'             => title,
    'date'              => date,
    'localIdentifier'   => local_id,
    'responseForm'      => 'xml' }
  response = RestClient.post(INGEST_SERVICE, params, { :multipart => true })
  @doc = Nokogiri::XML(response) do |config|
    config.strict.noent.noblanks
  end
end

def mk_manifest(urls)
  manifest = Tempfile.new("mrt-atom-ingester")
  manifest.write("#%checkm_0.7\n")
  manifest.write("#%profile http://uc3.cdlib.org/registry/ingest/manifest/mrt-ingest-manifest\n")
  manifest.write("#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom#\n")
  manifest.write("#%prefix | nfo: | http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#\n")
  manifest.write("#%fields | nfo:fileUrl | nfo:hashAlgorithm | nfo:hashValue | nfo:fileSize | nfo:fileLastModified | nfo:fileName | mrt:mimeType\n")
  urls.each do |url|
    filename = url.gsub(/^https?:\/\//, '')
    manifest.write("#{url} | | | | | #{filename} |\n")
  end
  manifest.write("#%EOF\n")
  manifest.open # reset manifest
  return manifest
end

def up_to_date?(store, local_id, last_updated)
  q = Q.new("?s object:localIdentfier \"#{local_id}")
  res = store().select(q)
  # ...
end

def process_atom_feed(submitter, profile, starting_point)
  next_page = starting_point
  n = 0
  until next_page.nil? do
    doc = Nokogiri::XML(open(next_page))
    doc.xpath("//atom:entry", NS).each do |entry|
      id = xpath_content(entry, "atom:id")
      updated = xpath_content(entry, "atom:updated")
      date = xpath_content(entry, "atom:published")
      title = xpath_content(entry, "atom:title")
      creator = entry.xpath("atom:author", NS).map { |au|
        xpath_content(au, "atom:name")
      }.join("; ")
      urls = entry.xpath("atom:link", NS).map { |link| link['href'] } + 
        entry.xpath(".//xhtml:img", NS).map { |img| img['src'] }
      manifest_file = mk_manifest(urls)
      ingest(submitter, profile, creator, title, date, id, manifest_file)
    end
    n = n + 1
    break if n == 10 # only 10 pages this time
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")
  end
end

# call as rake "atom:update[http://opencontext.org/all/.atom, egh/Erik Hetzner, ucb_open_context_content]"
namespace :atom do
  task :update, :root, :user, :profile, :needs => :environment do |cmd, args|
    process_atom_feed(args[:user], args[:profile], args[:root])
  end
end
