# this all probably needs to be refactored eventually
class Group
  LDAP = GroupLdap::Server.
    new({ :host            => LDAP_HOST,
          :port            => LDAP_PORT,
          :base            => LDAP_GROUP_BASE,
          :admin_user      => LDAP_ADMIN_USER,
          :admin_password  => LDAP_ADMIN_PASSWORD,
          :minter          => LDAP_ARK_MINTER_URL})

  Q = Mrt::Sparql::Q
  STORE = Mrt::Sparql::Store.new(SPARQL_ENDPOINT)

  attr_accessor :id, :submission_profile, :ark_id, :owner, :description

  def initialize

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
    "http://uc3.cdlib.org/collection/#{URI.encode(self.id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
  end

  def object_count
    return STORE.select(Q.new("?obj rdf:type object:Object .
      ?obj object:isStoredObjectFor ?meta .
      ?meta object:isInCollection <#{self.sparql_id}>", :select=>"?obj")).size
  end

  def version_count
    return STORE.select(Q.new("?vers rdf:type version:Version .
        ?vers version:inObject ?obj .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{self.sparql_id}>", :select=>"?vers")).size
  end

  def file_count
    return STORE.select(Q.new("?file rdf:type file:File .
        ?file file:inVersion ?vers .
        ?vers version:inObject ?obj .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{self.sparql_id}>", :select=>"?file")).size
  end

  def total_size
    q = Q.new("?obj rdf:type object:Object .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{self.sparql_id}> .
        ?obj object:totalActualSize ?size",
      :select => "?size")
    return STORE.select(q).map{|row| row['size'].value.to_i}.sum
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
