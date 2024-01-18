# TODO: remove this, then remove it from exclude list in top-level .rubocop.yml
module DuaMixin

  # :nocov:
  # returns the response of the HTTP request for the DUA URI
  def process_dua_request(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    uri_response = http.request(Net::HTTP::Get.new(uri.request_uri))
    uri_response.instance_of?(Net::HTTPOK)
  end
  # :nocov:

  # :nocov:
  # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def check_dua(object, redirect_args)
    # bypass DUA processing for python scripts - indicated by special param
    return if params[:blue]

    puts 333
    puts session
    puts 444
    puts session.keys
    puts 555
    puts redirect_args

    session[:collection_acceptance] ||= Hash.new(false)
    # check if user already saw DUA and accepted: if so, return
    if session[:collection_acceptance][object.group.id]
      # clear out acceptance if it does not have session persistence
      session[:collection_acceptance].delete(object.group.id) if session[:collection_acceptance][object.group.id] != 'session'
      nil
    elsif object.dua_exists? && process_dua_request(object.dua_uri)
      # if the DUA for this collection exists, display DUA to user for acceptance before displaying file
      puts 666
      redirect_to({ controller: 'dua', action: 'index' }.merge(redirect_args)) && return
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  # :nocov:
end
