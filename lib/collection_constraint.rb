class CollectionConstraint
  def matches?(request)
    if request.params[:group].blank?
      false
    elsif !request.params[:group].match(/^ark/)
      # TODO: what if some collection is NAMED 'ark'-something?
      # collection mneumonic
      true
    else
      # TODO: pass this result in to controller so we don't fetch twice
      begin
        Group.find(request.params[:group])
        return true
      rescue LdapMixin::LdapException
        return false
      end
    end
  end
end
