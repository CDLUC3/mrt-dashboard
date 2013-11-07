require 'net/http'
require 'tempfile'

class LostorageController < ApplicationController
  before_filter :require_user
  before_filter :require_group

  include Encoder

  def index 
    if params[:commit] == "Submit" then
      if params[:user_agent_email].blank? then
        flash[:message] = 'Please enter the required fields' and return
      elsif !params[:user_agent_email].match(/^.+@.+$/) then
        flash[:message] = 'You must fill in a valid return email address.' and return
      else 
        resp = post_los_email(params[:user_agent_email])
        
        if (resp.code == 200) then
          session[:perform_async] = true
          flash[:notice] = "Processing of large object compression has begun.  Please look for an email in your inbox"
        else
          #TODO: flash error messages are not displaying properly
          flash[:error] = "Error processing large object in storage service.  Please contact uc3@ucop.edu" and return
        end
        redirect_to session[:return_to]
      end
    elsif params[:commit] == "Cancel" then
      session[:perform_async] = "cancel"
      redirect_to session[:return_to]
    end
  end
  
  def post_los_email(email)
    create_email_msg_body(email)
    lostorage_xml_email_profile = create_los_email
    
    @lostorage_args = {
      'email'             => lostorage_xml_email_profile,
      'responseForm'      => 'xml',
      'containerForm'     => "targz",
      'name'              => @email_data['name']        
    }
    
    #construct the async storage URL using the object's state storage URL-  Sub async for state in URL.
    storage_url = InvObject.find_by_ark(session[:object]).bytestream_uri
    storage_async_url = storage_url.to_s.gsub(/content/,'async')
    resp = RestClient.post(storage_async_url, @lostorage_args, {:multipart => true })
    lostorage_xml_email_profile.close!
    return resp
  end

  def create_email_msg_body(email)
    to_email = Array(email).concat( APP_CONFIG['lostorage_email_to'])          
    session[:version].nil? ? container_type = "object" : container_type = "version"
    #Create theemail URL to include in the body which includes a random name for stored container
    uri_name = UUIDTools::UUID.random_create().hash.to_s + '.tar.gz'
    link_info = "The #{container_type} that you requested is ready for you to download. " +
      "Please click on the link to download your file: \n\n #{CONTAINER_URL + uri_name} \n\n" +
      "Please note that this link will expire in 7 days from the date of this email.   \n\n" +
      "The content is stored as a compressed file in the \"tar.gz\" format. For an explanation of " +
      "how to extract the files in this container, see http://www.gzip.org/#faq6. \n\n" +
      "If you have any questions regarding the download of this archive, please contact uc3@cdlib.org."
    
    #TODO: clean this up so all the text is in a template       
    @email_data = {
      'from'       => APP_CONFIG['lostorage_email_from'],
      'to_email'   => to_email,
      'collection' => @group.description,
      'object'     => urlencode_mod(session[:object]),
      'version'    => session[:version],
      'subject'    => "Merritt #{container_type.capitalize} Download Processing Completed ",
      'link_info'  => link_info,
      'name'       => uri_name }
    email_body = render_to_string( :partial => "lostorage/los_email_body.text.erb")      
    @email_data['email_body'] = email_body    
  end

  def create_los_email
    tempfile = Tempfile.new("mail.xml")
    xml = Builder::XmlMarkup.new :target => tempfile
    xml.instruct!
    xml.email do
      xml.from @email_data['from']
      @email_data['to_email'].each do |x|
        xml.to x
      end
      xml.subject @email_data['subject']
      xml.msg @email_data['email_body']
    end
    tempfile.rewind  #POST request needs this done to process the file properly as an argument
    return tempfile
  end
end
