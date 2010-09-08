# this all probably needs to be refactored eventually
class Group

  Q = Mrt::Sparql::Q
  STORE = Mrt::Sparql::Store.new(SPARQL_ENDPOINT)

  attr_accessor :id, :submission_profile, :ark_id, :owner, :description

  def initialize

  end

  def self.find(id)
    grp = LDAP_GROUP.fetch(id)
    g = self.new
    g.id = simplify_single_value(grp, 'ou')
    g.submission_profile = simplify_single_value(grp, 'submissionprofile')
    g.ark_id = simplify_single_value(grp, 'arkid')
    g.owner = simplify_single_value(grp, 'owner')
    g.description = simplify_single_value(grp, 'description')
    return g
  end

  # XXX a random number of objects since we don't know yet
  def object_count
    rand(10000)
  end

  # permissions are returned as an array like ['read','write'], maybe more in the future
  def permission(userid)
    LDAP_GROUP.get_user_permissions(userid, self.id, LDAP_USER)
  end

  def sparql_id
    "http://uc3.cdlib.org/collection/#{URI.encode(self.id, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))}"
  end

  def object_count
    STORE.select(Q.new("?obj rdf:type object:Object .
      ?obj object:isStoredObjectFor ?meta .
      ?meta object:isInCollection <#{self.sparql_id}>")).size
  end

  def version_count
    STORE.select(Q.new("?vers rdf:type version:Version .
        ?vers version:inObject ?obj .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{self.sparql_id}>")).size
  end

  def file_count
    STORE.select(Q.new("?file rdf:type file:File .
        ?file file:inVersion ?vers .
        ?vers version:inObject ?obj .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{self.sparql_id}>")).size
  end

  def total_size
    q = Q.new("?obj rdf:type object:Object .
        ?obj object:isStoredObjectFor ?meta .
        ?meta object:isInCollection <#{self.sparql_id}>",
      :select => "?obj")

    obs = STORE.select(q).map{|s| UriInfo.new(s['obj']) }

    total_size = 0

    obs.each{|ob| total_size += ob[Mrt::Object.totalActualSize].to_s.to_i}
    total_size
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
