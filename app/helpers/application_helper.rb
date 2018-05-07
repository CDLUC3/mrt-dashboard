module ApplicationHelper
  # from http://codesnippets.joyent.com/posts/show/1812
  def formatted_int(i)
    if i.nil? then "0"
    elsif (i.abs < 1000) then i.to_s
    else i.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,") end
  end

  def permissions(array)
    if (array.length == 0) then "none"
    elsif (array.length == 1) then "#{array[0]} only"
    else array.join("/") end
  end

  def merritt_time(t)
    t = DateTime.parse(t.to_s) if (t.class != DateTime)
    t = t.utc if (! t.utc?)
    t.strftime("%Y-%m-%d %I:%M %p UTC")
  end

  def clean_mime_type(mt)
    mt.gsub(/;.*$/, '')
  end

  # Format kernel metadata lists
  def dc_nice(vals)
    if (vals.nil? || vals.empty?) then ""
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
