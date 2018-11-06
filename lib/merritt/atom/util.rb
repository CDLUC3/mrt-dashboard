require 'rails'
require 'time'

module Merritt
  module Atom
    module Util
      def log_info(message)
        if (log = Rails.logger)
          log.info(message)
        else
          $stdout.puts(message)
        end
      end

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

      def parse_time(time_str)
        Time.parse(time_str)
      rescue ArgumentError => e
        log_error("Unable to parse #{time_str}", e)
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
