# -*- mode: ruby -*-
# Script for ingesting items into Merritt by parsing an Atom feed.
#
# Author::    Erik Hetzner (mailto:erik.hetzner@ucop.edu)
# Copyright:: Copyright (c) 2011 Regents of the University of California

require 'webrick'
require 'tmpdir'
require 'fileutils'

# An HTTP server that will serve each file ONCE.
class OneTimeServer
  # Find an open port, starting with start and adding one until we get
  # an open port
  def get_open_port(start=8080)
    try_port = start
    while (true)
      begin
        s = TCPServer.open(try_port)
        s.close
        return try_port
      rescue Errno::EADDRINUSE
        try_port = try_port + 1
      end
    end
  end
  
  def initialize
    @dir = Dir.mktmpdir
    @requested = {}
    file_callback = lambda do |req,res|
      @requested[req.path] ||= true
    end
    @port = get_open_port()
    config = { :Port => @port }
    @server = WEBrick::HTTPServer.new(config)
    @server.mount("/", WEBrick::HTTPServlet::FileHandler, @dir,
                  { :FileCallback=>file_callback })
  end

  # Return true if each file has been served.
  def finished?
    Dir.entries(@dir).each do |entry|
      next if (entry == "." || entry == "..")
      if @requested["/#{entry}"].nil? then
        return false
      end
    end
    return true
  end
  
  # Add a file to this server. Returns the URL to use to fetch the
  # file.
  def add_file
    tmpfile = Tempfile.new("tmp", @dir)
    tmpfile_path = tmpfile.path
    tmpfile.close!
    File.open(tmpfile_path, 'w+') do |f|
      yield f
    end
    return "http://#{Socket.gethostname}:#{@port}/#{File.basename(tmpfile_path)}"
  end

  # Run the server and wait until each file has been served once.
  # Cleans up files before it returns.
  def run
    @thread = Thread.new do
      @server.start
    end
    @thread.run
    # ensure that each file is requested once before shutting down
    while (!self.finished?) do sleep(1) end
    @server.shutdown 
    @thread.join
#    FileUtils.rm_rf(@dir)
    return
  end
end

# Namespaces
NS = { "atom"  => "http://www.w3.org/2005/Atom",
       "xhtml" => "http://www.w3.org/1999/xhtml" }

PAGE_DELAY = 10 # delay between each page we process

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
    'responseForm'      => 'xml' }
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
  urls.each do |url, filename|
    manifest.write("#{url} | | | | | #{filename} |\n")
  end
  manifest.write("#%EOF\n")
end

# Create ERC file.
def mk_erc(erc, creator, title, date, local_id, created, modified)
  erc.write("who: #{creator}\n")
  erc.write("what: #{title}\n")
  erc.write("when: #{date}\n")
  erc.write("where: #{local_id}\n")
  erc.write("when/created: #{created}\n")
  erc.write("when/modified: #{modified}\n")
end

def up_to_date?(store, local_id, last_updated)
  q = Q.new("?s object:localIdentfier \"#{local_id}")
  res = store().select(q)
  # ...
end

def process_atom_feed(server, submitter, profile, starting_point)
  next_page = starting_point
  n = 0
  until next_page.nil? do
    doc = Nokogiri::XML(open(next_page))
    doc.xpath("//atom:entry", NS).each do |entry|
      id = xpath_content(entry, "atom:id")
      modified = xpath_content(entry, "atom:updated")
      date = xpath_content(entry, "atom:published")
      title = xpath_content(entry, "atom:title")
      creator = entry.xpath("atom:author", NS).map { |au|
        xpath_content(au, "atom:name")
      }.join("; ")
      urls = entry.xpath("atom:link", NS).map do |link| 
        url = link['href']
        filename = url.gsub(/^https?:\/\//, '')
        [url, filename]
      end

      # Make mrt-erc.txt file & add to list of urls to ingest
      erc_url = server.add_file do |erc|
        mk_erc(erc, creator, title, date, id, date, modified)
      end
      urls.push([erc_url, 'mrt-erc.txt'])

      # Make manifest file.
      manifest_file = Tempfile.new("mrt-atom-ingester")
      mk_manifest(manifest_file, urls)
      manifest_file.open
     
      ingest(submitter, profile, creator, title, date, id, manifest_file)
    end
    n = n + 1
    break if n == 10 # only 10 pages this time
    next_page = xpath_content(doc, "/atom:feed/atom:link[@rel=\"next\"]/@href")
    sleep(PAGE_DELAY)
  end
end

# call as rake "atom:update[http://opencontext.org/all/.atom, egh/Erik Hetzner, ucb_open_context_content]"
namespace :atom do
  task :update, :root, :user, :profile, :needs => :environment do |cmd, args|
    server = OneTimeServer.new
    process_atom_feed(server, args[:user], args[:profile], args[:root])
    # Run server and wait until ingest is finished.
    server.run
  end
end
