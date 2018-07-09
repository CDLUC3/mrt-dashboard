require 'net/http'
require 'uri'

module Noid
  class MintException < RuntimeError; end

  class Minter
    def initialize(url_string, n_at_once = 1, preserve_naan = false)
      @url           = URI.parse(url_string)
      @n_at_once     = n_at_once
      @preserve_naan = preserve_naan
      @cache         = []
    end

    # rubocop:disable Lint/RescueException
    def mint
      (@cache = request_more_ids) if @cache.empty?
      @cache.shift
    rescue MintException
      raise # don't eat our own exceptions
    rescue SocketError
      raise MintException, 'Could not connect to server.'
    rescue Exception # TODO: should this be StandardError (or just 'rescue')?
      raise MintException, "Can't get ID; not a NOID server?"
    end
    # rubocop:enable Lint/RescueException

    private

    def request_more_ids
      request  = Net::HTTP::Get.new(@url.path + '?mint+' + @n_at_once.to_s)
      response = Net::HTTP.start(@url.host, @url.port) { |http| http.request(request) }
      raise MintException, 'Got error response from server.' unless response.code == '200'
      extract_ids(response.body)
    end

    def extract_ids(body)
      body.split(/\n/).map do |s|
        md = s.match(%r{id:\s+([0-9]+/)?([^\s]+)})
        @preserve_naan ? "#{md[1]}#{md[2]}" : md[2]
      end
    end

  end
end
