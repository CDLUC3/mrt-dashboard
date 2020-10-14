require 'httpclient'
require 'net/http'

module HttpMixin
  TEMPORARY_REDIRECT = HTTP::Status::TEMPORARY_REDIRECT
  PERMANENT_REDIRECT = 308 # per RFC 7538

  def mk_httpclient
    client = HTTPClient.new
    client.receive_timeout = 7200
    client.send_timeout = 3600
    client.connect_timeout = 7200
    client.keep_alive_timeout = 3600
    client
  end

  def http_post(url, params = {})
    client = mk_httpclient
    retry_number = 0
    loop do
      resp = client.post(url, params)
      return resp unless post_redirect?(resp)
      raise retry_count_exceeded(resp) if (retry_number += 1) > client.follow_redirect_count

      # Rails5 - seems to be obsolete
      # rewind_any_files(params)
      url = redirect_url_from(resp)
    end
  end

  def post_redirect?(resp)
    resp.status == TEMPORARY_REDIRECT || resp.status == PERMANENT_REDIRECT
  end

  def redirect_url_from(resp)
    redirect_url = resp.headers['Location']
    redirect_url = redirect_url[0] if redirect_url.is_a?(Enumerable)
    return redirect_url if redirect_url

    raise missing_location(resp)
  end

  private

  def retry_count_exceeded(resp)
    HTTPClient::BadResponseError.new('retry count exceeded', resp)
  end

  def missing_location(resp)
    HTTPClient::BadResponseError.new('Missing Location header for redirect', resp)
  end

  # def rewind_any_files(arg)
  #  return arg.rewind if arg.respond_to?(:rewind)
  #  return arg.each_value { |v| rewind_any_files(v) } if arg.respond_to?(:each_value)
  #
  #  arg.each { |v| rewind_any_files(v) } if arg.respond_to?(:each)
  # end

end
