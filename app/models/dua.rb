class Dua
  #:nocov:
  def self.parse_file(dua_file)
    # regex to capture match of name:value and put them into a hash
    rx = /(\w+)\s*:\s*(.+)/
    a = []
    File.open(dua_file.path) do |f|
      while (line = f.gets)
        unless rx.match(line).nil?
          a << $LAST_MATCH_INFO.captures.map(&:strip) # clean up the entries
        end
      end
      a.to_h
    end
  end
  #:nocov:
end
