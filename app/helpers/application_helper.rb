module ApplicationHelper
  def w3cdtf(time)
    case time
    when Time, DateTime
      return time.strftime("%Y-%m-%dT%H:%M:%S#{time.formatted_offset}")
    end
  end

  # from http://codesnippets.joyent.com/posts/show/1812
  def formatted_int(i)
    if i.nil? then "0"
    elsif (i.abs < 1000) then i.to_s
    else i.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,") end
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
    if (array.length == 0) then "none"
    elsif (array.length == 1) then "#{array[0]} only"
    else array.join("/") end
  end

  def merritt_time(t)
    t = DateTime.parse(t.to_s) if (t.class != DateTime)
    t.strftime("%Y-%m-%d %I:%M %p UTC")
  end

  def clean_mime_type(mt)
    mt.gsub(/;.*$/, '')
  end

  # Format kernel metadata lists
  def dc_nice(vals)
    if (vals.nil? || vals.empty?) then "[this space intentionally left blank]"
    else vals.join("; ") end
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
    if !Rails.env.include?('production') then Rails.env
    else "" end
  end

  # Return true if a user is logged in
  def user_logged_in?
    return !session[:uid].blank?
  end
  
  # Return true if logged in as guest
  def guest_logged_in?
    user_logged_in? && (session[:uid] == (LDAP_CONFIG["guest_user"]))
  end
  
  # Return true if user has choosen a group
  def group_choosen?
    return !session[:group_id].nil?
  end
end
