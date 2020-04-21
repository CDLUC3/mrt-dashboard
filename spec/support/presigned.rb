require 'rails_helper'

def mock_httpclient
  client = instance_double(HTTPClient)
  allow(client).to receive(:follow_redirect_count).and_return(10)
  %i[receive_timeout= send_timeout= connect_timeout= keep_alive_timeout=].each do |m|
    allow(client).to receive(m)
  end
  allow(HTTPClient).to receive(:new).and_return(client)
  client
end

def mock_response(status = 200, message = '', json = {})
  json['status'] = status
  json['message'] = message
  mockresp = instance_double(HTTP::Message)
  allow(mockresp).to receive(:status).and_return(status)
  allow(mockresp).to receive(:content).and_return(json.to_json)
  mockresp
end
