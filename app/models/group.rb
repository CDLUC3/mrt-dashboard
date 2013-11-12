# this all probably needs to be refactored eventually
class Group
  LDAP = GroupLdap::Server.
    new({ :host            => LDAP_CONFIG["host"],
          :port            => LDAP_CONFIG["port"],
          :base            => LDAP_CONFIG["group_base"],
          :admin_user      => LDAP_CONFIG["admin_user"],
          :admin_password  => LDAP_CONFIG["admin_password"],
          :minter          => LDAP_CONFIG["ark_minter_url"]})

  attr_accessor :id, :submission_profile, :ark_id, :owner, :description

  def initialize
  end

  def to_param
    self.id
  end
  
  def self.find_all
    LDAP.find_all
  end

  def self.find_users(grp_id)
    LDAP.find_users(grp_id)
  end

  def self.find_batch(ids)
    Group::LDAP.fetch_batch(ids).map{|l| self.make_from_ldap(l)}
  end

  def self.find(id)
    #fetch by groupid, but otherwise, fall back to arkid
    ldap_group = begin
                   Group::LDAP.fetch(id)
                 rescue LdapMixin::LdapException => ex
                   Group::LDAP.fetch_by_ark_id(id)
                 end
    return self.make_from_ldap(ldap_group)
  end
  
  # permissions are returned as an array like ['read','write'], maybe more in the future
  def permission(userid)
    @permissions ||= {}
    @permissions[userid] ||= Group::LDAP.get_user_permissions(userid, self.id, User::LDAP)
  end

  def sparql_id
    return "http://ark.cdlib.org/#{self.ark_id}"
  end

  def inv_collection
    @inv_collection ||= InvCollection.find_by_ark(self.ark_id)
  end

  def inv_collection_id
    @inv_collection_id ||= if self.inv_collection then self.inv_collection.id else nil end
  end

  def object_count
    if self.inv_collection_id.nil? then
      0
    else
      InvObject.connection.select_all("SELECT COUNT(DISTINCT(`inv_objects`.id)) as `count` FROM `inv_objects` INNER JOIN `inv_collections_inv_objects` ON `inv_objects`.id = `inv_collections_inv_objects`.inv_object_id WHERE ((`inv_collections_inv_objects`.inv_collection_id = #{self.inv_collection_id}))")[0]["count"].to_i
    end
  end
  
  def version_count
    if self.inv_collection_id.nil? then
      0
    else
      InvObject.connection.select_all("SELECT COUNT(DISTINCT(`inv_versions`.id)) AS `count` FROM `inv_versions` INNER JOIN `inv_objects` ON `inv_objects`.`id` = `inv_versions`.`inv_object_id` INNER JOIN `inv_collections_inv_objects` ON `inv_objects`.`id` = `inv_collections_inv_objects`.`inv_object_id` WHERE ((`inv_collections_inv_objects`.inv_collection_id = #{self.inv_collection_id}))")[0]["count"].to_i
    end
  end

  def file_count
    if self.inv_collection_id.nil? then
      0
    else
      InvFile.connection.select_all("SELECT COUNT(DISTINCT(`inv_files`.`id`)) AS `count` FROM `inv_files` INNER JOIN `inv_versions` ON `inv_versions`.`id` = `inv_files`.`inv_version_id` INNER JOIN `inv_objects` ON `inv_objects`.`id` = `inv_versions`.`inv_object_id` INNER JOIN `inv_collections_inv_objects` ON `inv_objects`.`id` = `inv_collections_inv_objects`.`inv_object_id` WHERE ((`inv_collections_inv_objects`.inv_collection_id = #{self.inv_collection_id}))")[0]["count"].to_i
    end
  end

  def total_size
    Rails.logger.info("Im in the total_size method of group model")
    if self.inv_collection.nil? then
      0
    else    
      InvFile.connection.select_all("SELECT SUM(full_size) AS `total_size` FROM `inv_files` INNER JOIN `inv_collections_inv_objects` ON `inv_collections_inv_objects`.`inv_object_id` = `inv_files`.`inv_object_id` WHERE (`inv_collections_inv_objects`.inv_collection_id = #{self.inv_collection_id})")[0]["total_size"].to_i
    end
  end

  #get all groups and email addresses of members, this is a stopgap for our own use
  def self.show_emails
    out_str = ''
    Group.find_all.each do |grp|
      out_str << "#{grp['ou'][0]}\r\n"
      Group.find_users(grp['ou'][0]).each do |usr|
        u = User::LDAP.fetch(usr)
        out_str << "#{u[:mail][0]}\r\n"
      end
      out_str << "\r\n"
    end
    out_str
  end
  
  private

  def self.make_from_ldap(ldap_group)
    g = self.new
    g.id                 = simplify_single_value(ldap_group, 'ou')
    g.submission_profile = simplify_single_value(ldap_group, 'submissionprofile')
    g.ark_id             = simplify_single_value(ldap_group, 'arkid')
    g.owner              = simplify_single_value(ldap_group, 'owner')
    g.description        = simplify_single_value(ldap_group, 'description')
    return g
  end

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
