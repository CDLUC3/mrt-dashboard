# this all probably needs to be refactored eventually
class Group

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
