module PaginationMixin
  include ErrorMixin

  def page_param
    param = params[:page]
    return unless param
    page = Integer(param)
    page >= 1 ? page : 1
  rescue StandardError => e
    logger.error(to_msg(e))
    1
  end

  def paginate_args
    { page: page_param, per_page: 10 }
  end
end
