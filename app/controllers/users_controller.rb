require 'sha1'
require 'base64'

class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user,    :only => [:show, :edit, :update]
  
  def get_ldap
    ldap = Net::LDAP.new()
    ldap.host = LDAP_HOST
    ldap.port = LDAP_PORT
    ldap.encryption(LDAP_ENCRYPTION)
    ldap.auth(LDAP_ADMIN_USER, LDAP_ADMIN_PASS)
    if !ldap.bind then
      raise Exception.new("Unable to bind to LDAP server.")
    end
    return ldap
  end

  def create
    login = params[:login]
    name = params[:name]
    (givenName, sn) = name.split(/ /)
    dn = "uid=#{login},#{LDAP_BASE}"
    # salt = File.read("/dev/urandom", 4)
    # passwd = Base64.encode64(Digest::SHA1.digest(params[:password] + salt) + salt).chomp! - not allowed with OpenDS
    attr = {
      :objectclass           => ["inetOrgPerson"],
      :uid                   => login,
      :sn                    => sn,
      :givenName             => givenName,
      :cn                    => name,
      :displayName           => name,
      :userPassword          => params[:password],
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
