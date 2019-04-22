class Streamer
  def initialize(url)
    @url = ensure_uri(url)
  end

  def each
    client = HTTPClient.new
    client.receive_timeout = 7200
    client.send_timeout = 3600
    client.connect_timeout = 7200
    client.keep_alive_timeout = 3600

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
