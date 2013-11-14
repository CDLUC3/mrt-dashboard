require 'net/http'
require 'tempfile'

class LostorageController < ApplicationController
  before_filter :require_user

  def index 
    if params[:commit] == "Submit" then
      if params[:user_agent_email].blank? then
        flash[:message] = 'Please enter the required fields' and return
      elsif !params[:user_agent_email].match(/^.+@.+$/) then
        flash[:message] = 'You must fill in a valid return email address.' and return
      else 
        if post_los_email(params[:user_agent_email]) then
          flash[:message] = "Processing of large object compression has begun.  Please look for an email in your inbox"
        else
          #TODO: flash error messages are not displaying properly
          flash[:error] = "Error processing large object in storage service.  Please contact uc3@ucop.edu"
        end
        redirect_to mk_merritt_url("m", params[:object], params[:version])
      end
    elsif params[:commit] == "Cancel" then
      redirect_to mk_merritt_url("m", params[:object], params[:version])
    end
  end
  
  def post_los_email(to_addr)
    unique_name = "#{UUIDTools::UUID.random_create().hash.to_s}.tar.gz"
    @object = InvObject.find_by_ark(params_u(:object))
    @container_type = (params[:version] && "version") || "object"
    @dl_url = "#{APP_CONFIG['container_url']}#{unique_name}"
    @version_number = params[:version]
    #construct the async storage URL using the object's state storage URL-  Sub async for state in URL.
    email_xml_file = build_email_xml(to_addr,
                                     "Merritt #{@container_type.capitalize} Download Processing Completed ",
                                     render_to_string(:formats => [:text],
                                                      :partial => "lostorage/los_email_body"))
    resp = RestClient.post(@object.bytestream_uri.to_s.gsub(/content/,'async'),
                           { 'email'             => email_xml_file,
                             'responseForm'      => 'xml',
                             'containerForm'     => "targz",
                             'name'              => unique_name },
                           { :multipart => true })
    email_xml_file.close!
    return (resp.code == 200)
  end

  def build_email_xml(to_addr, subject, body)
    tempfile = Tempfile.new("mail.xml")
    xml = Builder::XmlMarkup.new :target => tempfile
    xml.instruct!
    xml.email do
      xml.from(APP_CONFIG['lostorage_email_from'])
      xml.to(to_addr)
      APP_CONFIG['lostorage_email_to'].each do |addr|
        xml.to(addr)
      end
      xml.subject(subject)
      xml.msg(body)
    end
    tempfile.rewind  #POST request needs this done to process the file properly as an argument
    return tempfile
  end
end
