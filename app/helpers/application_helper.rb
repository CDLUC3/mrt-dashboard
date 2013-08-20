
module ApplicationHelper
  #takes an ark id and strips it down to just that if it's a RDF full uri
  def clean_id(id)
    id.to_s.match(/ark:\/[0-9a-z]+\/\S+$/)[0].to_s
  end

  #takes an ark id and returns full rdf uri
  def rdf_id(id)
    "#{RDF_ARK_URI}#{clean_id(id)}"
  end
  
  def version_no(uri)
    md = uri.to_s.match(/\/([0-9]+)$/)
    return md[1]
  end

  def w3cdtf(time)
    case time
    when Time, DateTime
      return time.strftime("%Y-%m-%dT%H:%M:%S#{time.formatted_offset}")
    when RDF::Literal
      w3cdtf(DateTime.parse(time.to_s))
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

  def have_permission(which)
    return current_permissions.include?(which)
  end

  def merritt_time(t)
    t = DateTime.parse(t.to_s) if (t.class != DateTime)
    t.strftime("%Y-%m-%d  %I:%M %p UTC")
  end

  # Format kernel metadata, filtering out unassigned values and
  # joining with ;.
  def dc_nice(i)
    if i.nil? || i.match(/\(:unas\)/)
      return ''
    end 
    i
  end

  #makes a tip over a question mark item, just pass in the text
  # requires javascript_include_tag 'wztip/wz_tooltip.js' on the page
  def help_tip(the_text)
    str = <<-eos
<a href="#" onmouseover="Tip('#{h(the_text).gsub("'", "\\'")}')">
  #{image_tag("tip_icon.gif", :size => '15x15')}
</a>
eos
    str.html_safe
  end

  # outputs a formatted string for the current environment, except production
  def show_environment
    if !Rails.env.include?('production') then
      Rails.env
    end
  end
end
