class Streamer
  def initialize(url)
    @url = url
  end
  
  def each 
    HTTPClient.new.get_content(@url) { |chunk|
      yield chunk
    }
  end
end
