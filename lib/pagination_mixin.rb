module PaginationMixin
  include ErrorMixin

  def page_param
    begin
      param = params[:page]
      return unless param
      page = Integer(param)
      return page unless page <= 1
      logger.warn("Can't show page #{page}; showing page 1")
    rescue StandardError => e
      logger.error(to_msg(e))
    end
    1
  end

  def paginate_args
    { page: page_param, per_page: 10 }
  end
end
