module ApplicationHelper
  def clean_id(id)
    if (md = id.to_s.match(/^(http:\/\/)(.*)$/)) then
      return URI.escape(md[2], Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    else
      return id.to_s
    end
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
    i.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
  end

  def permissions(array)
    return "none" if array.length < 1
    return "#{array[0]} only" if array.length == 1
    return array.join('/')
  end

  def crumb_path(id_arr)
    locations = {'merritt' => ['Merritt', {:controller => 'home', :action => 'index'}]
    }
    html_nuggets = id_arr.map do |id|
      if !locations[id].nil? then
        link_to(locations[id][0], locations[id][1])
      else
        nil
      end
    end
    "#{html_nuggets.compact.join(" &gt; ")} &gt; "
  end

end
