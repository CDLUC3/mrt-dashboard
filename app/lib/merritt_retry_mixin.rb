# Exception for mysql retries
module MerrittRetryMixin
  class RetryException < RuntimeError
    def initialize(message: 'RetryException', status: 500)
      super(message)
      @status = status
    end

    attr_reader :status
  end

  RETRY_LIMIT = 5

  # Merritt UI was encountering 500 errors on database connections that were no longer active.
  # The first solution that I tried was to wrap frequent query blocks with the following retry logic.
  # This significantly decreased the number of 500 errors.
  # In Jan 2024, I also began setting "idle_timeout=0".  Hopefully, this will address the underlying issue.
  # For each retry block that is invoked, there is an RSpec test that forces the code into the retry logic.
  def merritt_retry_block(action = '')
    retries = 0
    begin
      yield
    rescue ActiveRecord::RecordNotFound => e
      raise e
    rescue StandardError => e
      retries += 1
      if retries > RETRY_LIMIT
        Rails.logger.error("Retries exhausted for [#{action}].  Clearing all active connections.")
        # ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.connection_handler.clear_all_connections!
        # yet to try: flush_idle_connections
        status = e.instance_of?(HTTPClient::ReceiveTimeoutError) ? 408 : 500
        raise RetryException.new(status: status), e
      end

      Rails.logger.error("Retrying Action [#{action}]: #{retries} of #{RETRY_LIMIT} due to: #{e.message}")
      sleep 1 * retries
      retry
    end
  end
end
