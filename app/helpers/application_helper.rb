module ApplicationHelper
  #takes an ark id and strips it down to just that if it's a RDF full uri
  def clean_id(id)
    id.to_s.match(/ark:\/\d+\/\S+$/).to_s
  end

  #takes an ark id and returns full rdf uri
  def rdf_id(id)
    "#{RDF_ARK_URI}#{clean_id(id)}"
  end

  def maybe_link(val, raw=nil)
    if val.kind_of? RDF::URI then
      return "<a href=\"/show/#{clean_id(val)}#{if raw then "?raw" else "" end}\">#{val}</a>".html_safe
    else
      return val
    end
  end
  
  def version_no(uri)
    md = uri.to_s.match(/\/([0-9]+)$/)
    return md[1]
  end

  def w3cdtf(time)
    case time
    when Time
      return time.strftime("%Y-%m-%dT%H:%M:%S#{time.formatted_offset}")
    when RDF::Literal
      w3cdtf(Time.parse(time.to_s))
    end
  end

  # from http://codesnippets.joyent.com/posts/show/1812
  def formatted_int(i)
    return "0" if i.nil?
    return i.to_s if i<1000 and i>-1000
    i.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  # Modeled after the rails helper that does all sizes in binary representations
  # but gives sizes in decimal instead with 1kB = 1,000 Bytes, 1 MB = 1,000,000 bytes
  # etc.
  #
  # Formats the bytes in +size+ into a more understandable representation.
  # Useful for reporting file sizes to users. This method returns nil if
  # +size+ cannot be converted into a number. You can change the default
  # precision of 1 in +precision+.
  #
  #  number_to_storage_size(123)           => 123 Bytes
  #  number_to_storage_size(1234)          => 1.2 kB
  #  number_to_storage_size(12345)         => 12.3 kB
  #  number_to_storage_size(1234567)       => 1.2 MB
  #  number_to_storage_size(1234567890)    => 1.2 GB
  #  number_to_storage_size(1234567890123) => 1.2 TB
  #  number_to_storage_size(1234567, 2)    => 1.23 MB
  def number_to_storage_size(size, precision=1)
    size = Kernel.Float(size)
    case
      when size == 1 then "1 Byte"
      when size < 10**3 then "%d B" % size
      when size < 10**6 then "%.#{precision}f KB"  % (size / 10.0**3)
      when size < 10**9 then "%.#{precision}f MB"  % (size / 10.0**6)
      when size < 10**12 then "%.#{precision}f GB"  % (size / 10.0**9)
      else                    "%.#{precision}f TB"  % (size / 10.0**12)
    end.sub('.0', '')
  rescue
    nil
  end

  def permissions(array)
    return "none" if array.length < 1
    return "#{array[0]} only" if array.length == 1
    return array.join('/')
  end

  def merritt_time(t)
    if t.class == String then
      my_t = Time.parse(t)
    else
      my_t = t
    end
    my_t.strftime("%Y-%m-%d  %I:%M %p").downcase
  end

  #makes dublin core metadatas display nicely if not assigned
  def dc_nice(i)
    return "unknown" if i.nil?
    (i.to_s.eql?("(:unas)") ? 'unknown' : i.to_s )
  end

end
