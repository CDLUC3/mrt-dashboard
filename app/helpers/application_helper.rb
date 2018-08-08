module ApplicationHelper
  # from http://codesnippets.joyent.com/posts/show/1812
  def formatted_int(i)
    return '0' if i.nil?
    return i.to_s if i.abs < 1000
    i.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end

  def permissions(array)
    return 'none' if array.empty?
    return "#{array[0]} only" if array.length == 1
    array.join('/')
  end

  # rubocop:disable Style/DateTime
  def merritt_time(t)
    # TODO: Figure out where we use this and whether DateTime is really best here
    t = DateTime.parse(t.to_s) if t.class != DateTime
    t = t.utc unless t.utc?
    t.strftime('%Y-%m-%d %I:%M %p UTC')
  end
  # rubocop:enable Style/DateTime

  def clean_mime_type(mt)
    mt.gsub(/;.*$/, '')
  end

  # Format kernel metadata lists
  def dc_nice(vals)
    return '' if vals.nil? || vals.empty?
    vals.join('; ')
  end

  # makes a tip over a question mark item, just pass in the text
  # requires javascript_include_tag 'wztip/wz_tooltip.js' on the page
  def help_tip(the_text)
    escaped_tooltip = html_escape(the_text).gsub("'", "\\'")
    tooltip_tag = <<~HTML
      <a href="#" onmouseover="Tip('#{escaped_tooltip}')">
        <img class="tip-icon" src="/images/tip_icon.svg" alt="(?)"/>
      </a>
    HTML
    tooltip_tag.html_safe
  end

  # outputs a formatted string for the current environment, except production
  def env_str
    @env_str ||= begin
      env = Rails.env
      env.include?('production') ? '' : env
    end
  end

  # Return true if a user is logged in
  def user_logged_in?
    !session[:uid].blank?
  end

  # Return true if logged in as guest
  def guest_logged_in?
    user_logged_in? && (session[:uid] == (LDAP_CONFIG['guest_user']))
  end

  # Return true if user has choosen a group
  def group_choosen?
    !session[:group_id].nil?
  end
end
