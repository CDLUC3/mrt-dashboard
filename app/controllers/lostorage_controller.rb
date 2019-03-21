require 'net/http'
require 'tempfile'

class LostorageController < ApplicationController
  before_filter :require_user

  EMAIL_INVALID_MSG = 'You must fill in a valid return email address.'.freeze
  EMAIL_BLANK_MSG = 'Please enter the required fields'.freeze
  SUCCESS_MSG = 'Processing of large object compression has begun.  Please look for an email in your inbox'.freeze
  STORAGE_ERROR_MSG = 'Error processing large object in storage service.  Please contact uc3@ucop.edu'.freeze

  def index
    if params[:commit] == 'Submit' && email_valid?
      do_submit!
    elsif params[:commit] == 'Cancel'
      redirect_to object_page_url
    end
  end

  def direct
    user_agent_email = params[:user_agent_email]
    render(nothing: true, status: 406) && return if user_agent_email.blank?
    render(nothing: true, status: 400) && return unless user_agent_email.match?(/^.+@.+$/)

    if post_los_request(user_agent_email, user_friendly?(params))
      # success
      render nothing: true, status: 200
    else
      render nothing: true, status: 503
    end
  end

  private

  def do_submit!
    if post_los_request(params[:user_agent_email], user_friendly?(params))
      flash[:message] = SUCCESS_MSG
    else
      flash[:error] = STORAGE_ERROR_MSG # TODO: flash error messages are not displaying properly
    end
    redirect_to object_page_url
  end

  def email_valid?
    user_agent_email = params[:user_agent_email]
    return true if user_agent_email && user_agent_email.match?(/^.+@.+$/)

    flash[:message] = user_agent_email.blank? ? EMAIL_BLANK_MSG : EMAIL_INVALID_MSG
  end

  def user_friendly?(params)
    user_friendly_param = params[:userFriendly]
    user_friendly_param.blank? || user_friendly_param.downcase.match?('true')
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def post_los_request(to_addr, user_friendly)
    @object         = InvObject.find_by_ark(params_u(:object))
    @version_number = params[:version]
    @container_type = @version_number ? 'version' : 'object'

    unique_name     = "#{UUIDTools::UUID.random_create.hash}.tar.gz"
    @dl_url         = "#{APP_CONFIG['container_url']}#{unique_name}"

    # Customize return email information
    @los_from    = params[:losFrom]
    @los_subject = subject_or_default(params[:losSubject])
    @los_body = render_body(params[:losBody])

    Tempfile.create('mail.xml') do |email_xml_file|
      resp = do_storage_post(email_xml_file, to_addr, unique_name, user_friendly)
      return HTTP::Status.successful?(resp.status)
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def object_page_url
    mk_merritt_url('m', params[:object], params[:version])
  end

  def subject_or_default(subject_param)
    subject_param.blank? ? "Merritt #{@container_type.capitalize} Download Processing Completed" : subject_param
  end

  def render_body(body_param)
    if body_param.blank?
      render_to_string(formats: [:text], partial: 'lostorage/los_email_body')
    else
      render_to_string(formats: [:text], inline: body_param)
    end
  end

  def do_storage_post(email_xml_file, to_addr, unique_name, user_friendly)
    build_email_xml(email_xml_file, @los_from, to_addr, @los_subject, @los_body)
    email_xml_file.rewind
    params = { 'email' => email_xml_file, 'responseForm' => 'xml', 'containerForm' => 'targz', 'name' => unique_name }
    HTTPClient.new.post(storage_url_for(@object, user_friendly), params)
  end

  def build_email_xml(tempfile, from_addr, to_addr, subject, body)
    xml = Builder::XmlMarkup.new(target: tempfile)
    xml.instruct!
    xml.email do
      xml.from(from_addr.blank? ? APP_CONFIG['lostorage_email_from'] : from_addr)
      xml.to(to_addr)
      APP_CONFIG['lostorage_email_to'].each { |addr| xml.to(addr) }
      xml.subject(subject)
      xml.msg(body)
    end
  end

  def storage_url_for(object, user_friendly)
    if user_friendly
      object.bytestream_uri2_async
    else
      object.bytestream_uri_async
    end
  end
end
