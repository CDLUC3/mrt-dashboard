require 'net/http'
require 'uri'

module Noid
  class MintException < Exception; end

  class Minter
    def initialize(url_string, n_at_once = 1, preserve_naan = false)
      @url, @n_at_once, @preserve_naan = URI.parse(url_string), n_at_once, preserve_naan
      @cache = []
    end

    def mint
      fill_cache if @cache.empty?
      return @cache.shift
    end

    private
    def fill_cache
      begin
        req = Net::HTTP::Get.new(@url.path + '?mint+' + @n_at_once.to_s)
        resp = Net::HTTP.start(@url.host, @url.port) do |http|
          http.request(req)
        end
        raise MintException.new('Got error response from server.') unless resp.instance_of? Net::HTTPOK
        @cache.concat(resp.body.split(/\n/).map do |s|
          md = s.match(/id:\s+([0-9]+\/)?([^\s]+)/)
          if @preserve_naan
            "#{md[1]}#{md[2]}"
          else
            md[2]
          end
        end)
      rescue MintException
        raise # don't eat our own exceptions
      rescue SocketError
        raise MintException.new('Could not connect to server.')
      rescue Exception # TODO: should this be StandardError (or just 'rescue')?
        raise MintException.new("Can't get ID; not a NOID server?")
      end
    end
  end
end
