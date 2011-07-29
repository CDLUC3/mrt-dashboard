require 'webrick'

# An HTTP server that will serve each file ONCE before shutting down.
module Mrt
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
      # ugh, we need to do this because Mrt::File resolves
      ::File.open(tmpfile_path, 'w+') do |f|
        yield f
      end
      return "http://#{Socket.gethostname}:#{@port}/#{::File.basename(tmpfile_path)}"
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
end

