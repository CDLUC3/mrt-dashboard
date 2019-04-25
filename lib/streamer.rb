class Streamer
  include HttpMixin

  def initialize(url)
    @url = ensure_uri(url)
  end

  def each
    client = mk_httpclient
    client.get_content(@url) do |chunk|
      yield chunk
    end
  end

  private

  def ensure_uri(url)
    return url if url.is_a?(URI::Generic)
    URI.parse(url)
  end
end
