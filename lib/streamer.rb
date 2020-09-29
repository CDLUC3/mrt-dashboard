class Streamer
  include HttpMixin

  def initialize(url)
    @url = ensure_uri(url)
  end

  def each(&block)
    client = mk_httpclient
    client.get_content(@url, &block)
  end

  private

  def ensure_uri(url)
    return url if url.is_a?(URI::Generic)

    URI.parse(url)
  end
end
