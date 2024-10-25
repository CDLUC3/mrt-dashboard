# Exception for mysql retries
module MerrittRetryMixin
  class RetryException < RuntimeError; end

  RETRY_LIMIT = 3

  # Merritt UI was encountering 500 errors on database connections that were no longer active.
  # The first solution that I tried was to wrap frequent query blocks with the following retry logic.
  # This significantly decreased the number of 500 errors.
  # In Jan 2024, I also began setting "idle_timeout=0".  Hopefully, this will address the underlying issue.
  # For each retry block that is invoked, there is an RSpec test that forces the code into the retry logic.
  def merritt_retry_block
    retries = 0
    begin
      yield
    rescue StandardError => e
      retries += 1
      if retries > RETRY_LIMIT
        Rails.logger.error('Retries exhausted.  Clearing all active connections.')
        # ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.clear_all_connections!
        # yet to try: flush_idle_connections
        raise RetryException, e
      end

      sleep 1
      retry
    end
  end
end
