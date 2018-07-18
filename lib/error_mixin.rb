module ErrorMixin
  def to_msg(error)
    msg = "#{error.class}: #{error}"
    if (backtrace = (error.respond_to?(:backtrace) && error.backtrace))
      backtrace.each { |line| msg << "\n" << line }
    end
    return msg unless (cause = (error.respond_to?(:cause) && error.cause))
    msg << "\nCaused by: " << to_msg(cause)
  end
end
