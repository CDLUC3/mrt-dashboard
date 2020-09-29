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
      rescue ArgumentError => e
        log_error("Unable to parse #{time_str}", e)
        default
      end

      # rubocop:disable Lint/UriEscapeUnescape
      def to_uri(url)
        # TODO: why do we do this?
        # Original comment says 'Found spaces in Riverside feed' but surely we could just fix the spaces?
        # https://github.com/CDLUC3/mrt-dashboard/commit/52cb31b9f326c3fdfee952e09575392f703c1170
        double_encoded = URI.escape(url)
        URI.parse(double_encoded)
      rescue URI::InvalidURIError
        # UCR feed has URLs with square brackets in them, could be one of those
        # https://github.com/CDLUC3/mrt-dashboard/commit/ec9ef6451668d423147e8e3a64b737235429854a
        escaped = { '[' => '%5B', ']' => '%5D' }.reduce(double_encoded) { |u, (k, v)| u.gsub(k, v) }
        # if that doesn't solve it, we'll go ahead and raise
        URI.parse(escaped)
      end
      # rubocop:enable Lint/UriEscapeUnescape

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
