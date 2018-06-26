require 'net/http'
require 'tempfile'

class LostorageController < ApplicationController
  before_filter :require_user

  def index
    if params[:commit] == 'Submit'
      if params[:user_agent_email].blank?
        (flash[:message] = 'Please enter the required fields') && return
      elsif !params[:user_agent_email].match(/^.+@.+$/)
        (flash[:message] = 'You must fill in a valid return email address.') && return
      else
        if post_los_email(params[:user_agent_email])
          flash[:message] = 'Processing of large object compression has begun.  Please look for an email in your inbox'
        else
          # TODO: flash error messages are not displaying properly
          flash[:error] = 'Error processing large object in storage service.  Please contact uc3@ucop.edu'
        end
        redirect_to mk_merritt_url('m', params[:object], params[:version])
      end
    elsif params[:commit] == 'Cancel'
      redirect_to mk_merritt_url('m', params[:object], params[:version])
    end
  end

  def direct
    # Check if a user friendly download request (default: yes)
    params[:userFriendly] = 'true' if params[:userFriendly].blank?

    # Check for mandatory email
    if params[:user_agent_email].blank?
      render nothing: true, status: 406
    elsif !params[:user_agent_email].match(/^.+@.+$/)
      render nothing: true, status: 400
    elsif post_los_email(params[:user_agent_email])
      # success
      render nothing: true, status: 200
    else
      render nothing: true, status: 503
    end
  end

  def post_los_email(to_addr)
    # Customize return email information
    @los_from    = params[:losFrom]
    @los_subject = params[:losSubject]
    @los_body    = params[:losBody]

    unique_name     = "#{UUIDTools::UUID.random_create.hash}.tar.gz"
    @object         = InvObject.find_by_ark(params_u(:object))
    @container_type = (params[:version] && 'version') || 'object'
    @dl_url         = "#{APP_CONFIG['container_url']}#{unique_name}"
    @version_number = params[:version]

    # Custom subject?
    @los_subject = "Merritt #{@container_type.capitalize} Download Processing Completed " if @los_subject.blank?

    # Custom body?
    @los_body = if @los_body.blank?
                  render_to_string(formats: [:text], partial: 'lostorage/los_email_body')
                else
                  render_to_string(formats: [:text], inline: @los_body)
                end

    # construct the async storage URL using the object's state storage URL-  Sub async for state in URL.
    email_xml_file = build_email_xml(@los_from, to_addr, @los_subject, @los_body)

    user_friendly = params[:userFriendly].downcase
    post_url      = @object.bytestream_uri.to_s.gsub(/content/, 'async')
    if user_friendly.match('true')
      # user friendly download
      post_url = @object.bytestream_uri2.to_s.gsub(/producer/, 'producerasync')
    end

    resp = HTTPClient.new.post(post_url,
                               { 'email'         => email_xml_file,
                                 'responseForm'  => 'xml',
                                 'containerForm' => 'targz',
                                 'name'          => unique_name })
    email_xml_file.close
    email_xml_file.unlink
    (resp.status == 200)
  end

  def build_email_xml(from_addr, to_addr, subject, body)
    tempfile = Tempfile.new('mail.xml')
    xml = Builder::XmlMarkup.new target: tempfile
    xml.instruct!
    xml.email do
      # Custom from?
      if from_addr.blank?
        xml.from(APP_CONFIG['lostorage_email_from'])
      else
        xml.from(from_addr)
      end
      xml.to(to_addr)
      APP_CONFIG['lostorage_email_to'].each do |addr|
        xml.to(addr)
      end
      xml.subject(subject)
      xml.msg(body)
    end
    tempfile.rewind # POST request needs this done to process the file properly as an argument
    tempfile
  end
end
