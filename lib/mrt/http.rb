require 'net/https'

module Mrt
  class HTTP
    RETRY_LIMIT = 3
    REDIRECT_LIMIT = 3

    attr_reader :host, :port, :ca_file, :key_file, :cert_file
    
    def initialize(scheme, host, port, ca_file=nil, key_file=nil, cert_file=nil)
      @scheme, @host, @port, @ca_file, @key_file, @cert_file = scheme, host, port, ca_file, key_file, cert_file
      @http = Net::HTTP.new(@host, @port)
      if (@scheme == 'https') then
        @http.use_ssl = true
        @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        @http.key = OpenSSL::PKey::RSA.new(File.read(@key_file))
        @http.cert = OpenSSL::X509::Certificate.new(File.read(@cert_file))
        @http.ca_file = @ca_file
        @http.ssl_timeout = 2
        @http.verify_depth = 2
      end
    end
    
    def set_debug_output(where)
      @http.set_debug_output(where)
    end

    def request(req)
      if block_given? then
        @http.request(req) do |resp|
          yield(resp)
        end
      else
        return @http.request(req)
      end
    end

    def timeout=(timeout)
      @http.read_timeout=timeout
    end

    def get(path, accept="*/*", retry_limit=RETRY_LIMIT, redirect_limit=REDIRECT_LIMIT)
      req = Net::HTTP::Get.new(path)
      req['Accept'] = accept
      self.request(req) do |resp|
        case resp
        when Net::HTTPRedirection
          raise Exception.new('Too many redirects') if (redirect_limit == 0)
          #only redirect on the same base server
          uri = URI.parse(resp['Location'])
          raise Exception.new('Cannot redirect to a new server') if (@port != uri.port or @host != uri.host)
          return get(uri.path, retry_limit, (redirect_limit - 1))
        when Net::HTTPServerError
          if (retry_limit > 0) then
            return get(path, (retry_limit - 1), redirect_limit)
          else
            raise ServerError.new(resp.to_s)
          end
        when Net::HTTPClientError
          raise Exception.new(resp.to_s)
        when Net::HTTPSuccess
          if block_given? then
            yield(resp)
          end
          return resp
        else
          raise Exception.new(resp.to_s)
        end
      end
    end
      
    def get_body(path, accept='*/*', retry_limit=RETRY_LIMIT, redirect_limit=REDIRECT_LIMIT)
      get(path, accept, retry_limit, redirect_limit) do |resp|
        return resp.body
      end
    end

    def get_xml(path,accept='application/xml')
      return XML::Parser.string(get_body(path, accept)).parse
    end
    
    def get_to_tempfile(path, accept='*/*', retry_limit=RETRY_LIMIT, redirect_limit=REDIRECT_LIMIT)
      file = Tempfile.new('was_http')
      get_to_file(path, file, accept, retry_limit, redirect_limit)
      return file
    end

    def get_to_file(path, path_or_file, accept='*/*', retry_limit=RETRY_LIMIT, redirect_limit=REDIRECT_LIMIT)
      self.get(path,accept,retry_limit,redirect_limit) do |resp|
        file = if (path_or_file.is_a?(String)) then
                 File.open(path_or_file, 'w')
               else path_or_file end
        begin
          resp.read_body do |b|
            file << b
          end
        ensure
          file.close
        end
      end
    end

    def post(path, data, content_type='application/xml', accept="*/*", 
	retry_limit=RETRY_LIMIT, redirect_limit=REDIRECT_LIMIT)

      headers = {'Content-Type' => "#{content_type}"}
      req = Net::HTTP::Post.new(path, headers)
      @http.request(req, data) do |resp|
        case resp
        when Net::HTTPRedirection
          raise Exception.new('Too many redirects') if (redirect_limit == 0)
          #only redirect on the same base server
          uri = URI.parse(resp['Location'])
          raise Exception.new('Cannot redirect to a new server') if (@port != uri.port or @host != uri.host)
          return post(uri.path, data, retry_limit, (redirect_limit - 1))
        when Net::HTTPServerError
          if (retry_limit > 0) then
            return post(path, data, (retry_limit - 1), redirect_limit)
          else
            raise ServerError.new(resp.to_s)
          end
        when Net::HTTPClientError
          raise Exception.new(resp.to_s)
        when Net::HTTPSuccess
          if block_given? then
            yield(resp)
          end
          return resp
        else
          raise Exception.new(resp.to_s)
        end
      end
    end


    def delete(path, accept="*/*", retry_limit=RETRY_LIMIT, redirect_limit=REDIRECT_LIMIT)
      req = Net::HTTP::Delete.new(path)
      req['Accept'] = accept
      self.request(req) do |resp|
        case resp
        when Net::HTTPRedirection
          raise Exception.new('Too many redirects') if (redirect_limit == 0)
          #only redirect on the same base server
          uri = URI.parse(resp['Location'])
          raise Exception.new('Cannot redirect to a new server') if (@port != uri.port or @host != uri.host)
          return get(uri.path, retry_limit, (redirect_limit - 1))
        when Net::HTTPServerError
          if (retry_limit > 0) then
            return get(path, (retry_limit - 1), redirect_limit)
          else
            raise ServerError.new(resp.to_s)
          end
        when Net::HTTPClientError
          raise Exception.new(resp.to_s)
        when Net::HTTPSuccess
          if block_given? then
            yield(resp)
          end
          return resp
        else
          raise Exception.new(resp.to_s)
        end
      end
    end

  end
end
