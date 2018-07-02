class Streamer
  def initialize(url)
    @url = url
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

  def whatever
    # TODO: remove me once we're sure coverage check fails in default rake task
    puts 'I am a method with no test coverage'
  end
end
