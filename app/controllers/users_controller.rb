require 'sha1'
require 'base64'

class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user,    :only => [:show, :edit, :update]
  
  def get_ldap
    ldap = Net::LDAP.new()
    ldap.host = "gales.cdlib.org"
    ldap.port = 389
    ldap.auth("cn=admin,dc=cdlib,dc=org", "1234")
    if !ldap.bind then
      raise Exception.new("Unable to bind to LDAP server.")
    end
    return ldap
  end

  def create
    salt = File.read("/dev/urandom", 4)
    login = params[:login]
    dn = "uid=#{login},ou=people,dc=cdlib,dc=org"
    passwd = Base64.encode64(Digest::SHA1.digest(params[:password] + salt) + salt).chomp!
    name = params[:name]
    (givenName, sn) = name.split(/ /)
    attr = {
      :objectclass           => ["inetOrgPerson"],
      :uid                   => login,
      :sn                    => sn,
      :givenName             => givenName,
      :cn                    => name,
      :displayName           => name,
      :userPassword          => "{SSHA}#{passwd}",
      :mail                  => params[:email],
      :title                 => params[:title],
      :postalAddress         => [""],
      :initials              => "#{givenName[0,1]}#{sn[0,1]}" }
    ldap = get_ldap()
    if !ldap.add(:dn => dn, :attributes => attr) then
      raise Exception.new(ldap.get_operation_result())
    else
      flash[:notice] = "Account registered!"
      redirect_back_or_default '/'
    end
  end
end
