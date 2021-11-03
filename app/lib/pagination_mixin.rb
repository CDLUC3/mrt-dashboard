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

  def max_per_page
    500
  end

  def per_page_param(defcount)
    begin
      param = params[:per_page]
      return defcount unless param

      per_page = Integer(param)
      return per_page unless per_page > max_per_page

      logger.warn("Can't show #{per_page} per_page; showing #{max_per_page}")
    rescue StandardError => e
      # :nocov:
      logger.error(to_msg(e))
      # :nocov:
    end
    max_per_page
  end

  def paginate_args(defcount = 10)
    { page: page_param, per_page: per_page_param(defcount) }
  end
end
