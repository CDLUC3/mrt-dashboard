class CollectionConstraint
  def matches?(request)
    group_param = request.params[:group]
    return false if group_param.blank?
    return true unless group_param.match?(/^ark/)

    begin
      Group.find(group_param)
    rescue LdapMixin::LdapException
      false
    end

    true
  end
end
