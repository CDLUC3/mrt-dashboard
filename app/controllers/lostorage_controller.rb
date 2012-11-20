require 'net/http'
require 'tempfile'

class LostorageController < ApplicationController
  before_filter :require_user
  before_filter :require_group
  
  
  def index 
    if params['commit'].eql?("Submit") then  
      if params[:user_agent_email].blank? then
        flash[:message] = 'Please enter the required fields'
        return
      end

      if  (params[:user_agent_email] =~ /^.+@.+$/).nil? then
        flash[:message] = 'You must fill in a valid return email address.'
        return
      end   
     
      # configure the post request & email
      # send POST request along with email to storage
      begin
        response_code = post_los_email(params[:user_agent_email])
        @doc = Nokogiri::XML(@response) do |config|
          config.strict.noent.noblanks
        end
  
      rescue Exception => ex
        begin
          # see if we can parse the error from async, if not then unknown error
          @doc = Nokogiri::XML(ex.response) do |config|
            config.strict.noent.noblanks
          end
          #TODO:  fix this so it processes the error response correctly
          @description = "async: #{@doc.xpath("//body")[0].children.text}"
          @error = "async: #{@doc.xpath("//exc:error")[0].child.text}"
        rescue Exception => ex
          @description = "ui: #{ex.message}"
          @error = ""
        end
        render :action => "async_error" and return      
      end
      # process return response code
      #TODO: flash error messages are not displaying properly
      if response_code != 200 then
      #   report error message
          flash[:error] = "Error processing large object in storage service.  Please contact uc3@ucop.edu"
      #   Rails.Logger.error = "Error sending POST to storage service : response code = #{response_code}"
      else
      #    user entered email, set flags to continue processing object/version download
          session[:perform_async] = true;
          flash[:notice] = "Processing of large object compression has begun.  Please look for an email in your inbox"
       end
      redirect_to session[:return_to]
    elsif params[:commit].eql?("Cancel") 
      session[:perform_async] = "cancel";
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
      }.reject{|k, v| v.blank? }
      
      storage_async_url = STORAGE_SERVICE + urlencode(session[:object])
      @response = RestClient.post(storage_async_url, @lostorage_args, {:multipart => true })
      lostorage_xml_email_profile.close!
      return @response.code
    end

  def create_email_msg_body(email)
     to_email = email #[email, APP_CONFIG['lostorage_email_to']].join("; ")                 
     session[:version].nil? ? container_type = "object" : container_type = "version"
     #Create email URL to include in the body which includes a random name for stored container
     uri_name = UUIDTools::UUID.timestamp_create().to_s
     link_info = "The #{container_type} that you requested is ready for you to download. " +
                   "Pleace click on the URI link #{CONTAINER_URL + uri_name} to access your archive."

#TODO: clean this up so all the text is in the template       
      @email_data = (
              {'from'       => APP_CONFIG['lostorage_email_from'],
               'to_email'   => to_email,
               'collection' => @group.description,
               'object'     => session[:object],
               'version'    => session[:version],
               'subject'    => "Merritt #{container_type.capitalize} File Processing Completed ",
               'link_info'  => link_info,
               'name'       => uri_name
               })
      email_body = render_to_string( :partial => "lostorage/los_email_body.text.erb")      
      @email_data['email_body'] = email_body    
   end

  def create_los_email
      tempfile = Tempfile.new("mail.xml")
      xml = Builder::XmlMarkup.new :target => tempfile
      xml.instruct!
      xml.email do
        xml.from @email_data['from']
        #TODO: fix to so that it can accept multiple addresses
        xml.to @email_data['to_email']
        xml.subject @email_data['subject']
        xml.msg @email_data['email_body']
    end
    tempfile.rewind  #POST request needs this done to process the file properly as an argument
    return tempfile
  end

end