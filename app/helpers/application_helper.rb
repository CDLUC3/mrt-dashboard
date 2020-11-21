module ApplicationHelper
  # from http://codesnippets.joyent.com/posts/show/1812
  def formatted_int(ival)
    return '0' if ival.nil?
    return ival.to_s if ival.abs < 1000

    ival.to_s.gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1,')
  end

  def permissions(array)
    return 'none' if array.empty?
    return "#{array[0]} only" if array.length == 1

    array.join('/')
  end

  def merritt_time(time)
    # TODO: Figure out where we use this and whether DateTime is really best here
    time = DateTime.parse(time.to_s) if time.class != DateTime
    time = time.utc unless time.utc?
    time.strftime('%Y-%m-%d %I:%M %p UTC')
  end

  def clean_mime_type(mimetype)
    mimetype.gsub(/;.*$/, '')
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
        <img class="tip-icon" src="#{image_path('tip_icon.svg')}" alt="(?)"/>
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
    !current_user.nil?
  end

  # Return true if logged in as guest
  def guest_logged_in?
    user_logged_in? && (session[:uid] == (LDAP_CONFIG['guest_user']))
  end

  # Return true if user has choosen a group
  def group_choosen?
    !current_group.nil?
  end

  # We discovered that filenames containing strings like " %BF " were being improperly decoded.
  # This code triple unencodes a presigned file link and then runs a regex expression upon it.
  # If the link appears to be an improper utf8 string, the link will be modified to escape and escaped percent sign
  def presigned_link_uri(object, version, file)
    url_for controller: :file,
            action: :presign,
            object: object,
            version: version,
            file: file

    # special logic to determine if percent encoding should be fixed in a display link
    # x = fileurl
    # x = Encoder.urlunencode(x)
    # x = Encoder.urlunencode(x)
    # x = Encoder.urlunencode(x)
    # fileurl.gsub('%2525', '%252525') unless x.valid_encoding?
  end

end
