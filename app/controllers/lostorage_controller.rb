require 'net/http'
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
     
      # configure the email
      to_email = [params[:user_agent_email] , 
                 APP_CONFIG['lostorage_email_to']].join(", ")
                 
     session[:version].nil? ? container_type = "object" : container_type = "version"
     email_body = "The #{container_type} that you requested is ready for you to download. " +
                   "Pleace click on the URI link below to access your archive."
        
      LostorageMailer.lostorage_email(
              {'title'      => "Merrit Large Object Download File",
               'to_email'   => to_email,
               'email'      => params[:user_agent_email],
               'collection' => @group.description,
               'object'     => session[:object],
               'version'    => session[:version],
               'body'       => email_body,
               'container_type' => container_type
               }).deliver
                 
       
       #user entered email, set flags to continue processing object/version download
       session[:perform_async] = true;
       redirect_to session[:return_to]
    elsif params[:commit].eql?("Cancel") 
       session[:perform_async] = "cancel";
       redirect_to session[:return_to]
    end
   end
   
end