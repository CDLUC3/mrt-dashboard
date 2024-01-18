# Exception for mysql retries
module MerrittRetryMixin
  class RetryException < RuntimeError; end

  RETRY_LIMIT = 3

  def merritt_retry_block
    retries = 0
    begin
      yield
    rescue StandardError => e
      retries += 1
    raise RetryException, e if retries > RETRY_LIMIT

      sleep 1
      retry
    end
  end
end