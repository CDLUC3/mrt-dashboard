require 'rails'

module Merritt
  module Atom
    module Logging
      def log_error(message, exception = nil)
        msg = message
        msg << ": #{exception}" if exception
        append_backtrace(msg, exception)

        if (log = Rails.logger)
          log.error(msg)
        else
          warn(msg)
        end
      end

      private

      def append_backtrace(msg, exception)
        backtrace = (exception.respond_to?(:backtrace) && exception.backtrace)
        return unless backtrace
        backtrace.each do |line|
          msg << "\n"
          msg << line
        end
      end
    end
  end
end
