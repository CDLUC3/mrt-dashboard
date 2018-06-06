class Dua
  #:nocov:
  def self.parse_file(dua_file)
    # regex to capture match of name:value and put them into a hash
    rx = /(\w+)\s*:\s*(.+)/
    a = []
    return File.open(dua_file.path) do |f| 
      while line = f.gets
        if !rx.match(line).nil?
          a << $~.captures.map {|entry| entry.strip}  # clean up the entries
        end  
      end
      Hash[a]
    end
  end
  #:nocov:
end

