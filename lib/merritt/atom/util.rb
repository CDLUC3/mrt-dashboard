require 'rails'
require 'time'

module Merritt
  module Atom
    module Util
      NS = {
        'atom' => 'http://www.w3.org/2005/Atom',
        'dc' => 'http://purl.org/dc/elements/1.1/',
        'nx' => 'http://www.nuxeo.org/ecm/project/schemas/tingle-california-digita/ucldc_schema',
        'opensearch' => 'http://a9.com/-/spec/opensearch/1.1/',
        'xhtml' => 'http://www.w3.org/1999/xhtml'
      }.freeze

      NEVER = Time.utc(0)

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

      def parse_time(time_str, default: NEVER)
        Time.parse(time_str)
      rescue ArgumentError => e
        log_error("Unable to parse #{time_str}", e)
        default
      end

      def xpath_content(node, query)
        match = node.at_xpath(query, NS)
        return unless match
        match.content
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
