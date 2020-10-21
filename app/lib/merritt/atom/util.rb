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
        (log = Rails.logger) && log.info(message)
        $stdout.puts(message)
      end

      def log_error(message, exception = nil)
        msg = message
        msg << ": #{exception}" if exception
        append_backtrace(msg, exception)

        (log = Rails.logger) && log.error(msg)
        warn(msg)
      end

      def parse_time(time_str, default: NEVER)
        Time.parse(time_str)
      rescue ArgumentError
        log_error("Unable to parse #{time_str}")
        default
      end

      def to_uri(url)
        # Prior to using Addresable::URI, we had special code for square bracket encoding
        double_encoded = Addressable::URI.escape(url)
        URI.parse(double_encoded)
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
