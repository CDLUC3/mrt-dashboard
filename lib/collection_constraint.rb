class CollectionConstraint
  def matches?(request)
    if request.params[:group].blank? then
      return false
    elsif !request.params[:group].match(/^ark/) then
      # collection mneumonic
      return true
    else
      # TODO: pass this result in to controller so we don't fetch twice
      if !Group.find(request.params[:group]).nil? then
        return true
      else
        return false
      end
    end
  end
end
