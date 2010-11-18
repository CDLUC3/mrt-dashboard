# this all probably needs to be refactored eventually
class Group
  LDAP = GroupLdap::Server.
    new({ :host            => LDAP_CONFIG["host"],
          :port            => LDAP_CONFIG["port"],
          :base            => LDAP_CONFIG["group_base"],
          :admin_user      => LDAP_CONFIG["admin_user"],
          :admin_password  => LDAP_CONFIG["admin_password"],
          :minter          => LDAP_CONFIG["ark_minter_url"]})

  Q = Mrt::Sparql::Q
  STORE = Mrt::Sparql::Store.new(SPARQL_ENDPOINT)

  attr_accessor :id, :submission_profile, :ark_id, :owner, :description

  def initialize

  end

  def self.find_all
    LDAP.find_all
  end

  def self.find_users(grp_id)
    LDAP.find_users(grp_id)
  end

  def self.find(id)
    grp = Group::LDAP.fetch(id)
    g = self.new
    g.id = simplify_single_value(grp, 'ou')
    g.submission_profile = simplify_single_value(grp, 'submissionprofile')
    g.ark_id = simplify_single_value(grp, 'arkid')
    g.owner = simplify_single_value(grp, 'owner')
    g.description = simplify_single_value(grp, 'description')
    return g
  end

  # permissions are returned as an array like ['read','write'], maybe more in the future
  def permission(userid)
    Group::LDAP.get_user_permissions(userid, self.id, User::LDAP)
  end

  def sparql_id
    return "http://ark.cdlib.org/#{self.ark_id}"
    #"http://uc3.cdlib.org/collection/#{URI.encode(self.id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
  end

  def object_count
    return STORE.select(Q.new("?obj base:isInCollection <#{self.sparql_id}> ;
                                    a object:Object .",
                              :select=>"(count(?obj) as c)"))[0]["c"].value.to_i
  end

  def version_count
    return STORE.select(Q.new("?obj a object:Object ;
                                    base:isInCollection <#{self.sparql_id}> ;
                                    dc:hasVersion ?vers .",
                              :select=>"(count(?vers) as c)"))[0]["c"].value.to_i
  end

  def file_count
    q = Q.new("?obj base:isInCollection <#{self.sparql_id}> .
               ?vers version:inObject ?obj ;
                     version:hasFile ?file .",
              :select=>"(count(?file) as c)")
    return STORE.select(q)[0]["c"].value.to_i
  end

  def total_size
    q = Q.new("?obj base:isInCollection <#{self.sparql_id}> ;
                    object:totalActualSize ?size",
      :select => "(sum(?size) as total)")
    return STORE.select(q)[0]["total"].value.to_i
  end

  #get all groups and email addresses of members, this is a stopgap for our own use
  def self.show_emails
    out_str = ''
    grps = Group.find_all
    grps.each do |grp|
      out_str << "#{grp['ou'][0]}\r\n"
      usrs = Group.find_users(grp['ou'][0])
      usrs.each do |usr|
        u = User::LDAP.fetch(usr)
        out_str << "#{u[:mail][0]}\r\n"
      end
      out_str << "\r\n"
    end
    out_str
  end


  private

  # this may belong to some ldap base class at some point
  def self.simplify_single_value(record, field)
    return nil if record[field].nil? or record[field][0].nil? or record[field][0].length < 1
    return record[field][0]
  end

  def self.simplify_multiple_value(record, field)
    return [] if record[field].nil? or record[field][0].nil? or record[field][0].length < 1
    return record[field]
  end
end
