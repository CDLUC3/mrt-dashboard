class Dua
  
  cattr_accessor :dua_hash
  
  def self.parse_file(dua_file)
    # regex to capture match of name:value and put them into a hash
    rx = /(\w+)\s*:\s*(.+)/
    a = []
    File.open(dua_file.path) do |f| 
      while line = f.gets
        if !rx.match(line).nil?
          $~.captures.each {|entry| entry.strip}  # clean up the entries
          a << $~.captures
        end  
      end
      @dua_hash = Hash[a]
    end
    return @dua_hash
  end
  
end

