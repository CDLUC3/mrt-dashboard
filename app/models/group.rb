# this all probably needs to be refactored eventually
class Group

  attr_accessor :id, :ezid_shoulder, :ark_id, :ezid_sponsor_code, :owner, :description

  def initialize

  end

  def self.find(id)
    grp = LDAP_GROUP.fetch(id)
    g = self.new
    g.id = simplify_single_value(grp, 'ou')
    g.ezid_shoulder = simplify_multiple_value(grp, 'ezidshoulder')
    g.ark_id = simplify_single_value(grp, 'arkid')
    g.ezid_sponsor_code = simplify_single_value(grp, 'ezidsponsorcode')
    g.owner = simplify_single_value(grp, 'owner')
    #member = simplify_multiple_value(grp, 'uniqueMember')
    #g.member = member.map{|u| u[/^uid=\S+?,ou/][4..-4]}
    g.description = simplify_single_value(grp, 'description')
    return g
  end

  # XXX a random number of objects since we don't know yet
  def object_count
    rand(10000)
  end

  # XXX a random permission since we don't have any yet
  def permission(userid)
    LDAP_GROUP.get_user_permissions(userid, self.id, LDAP_USER)
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
