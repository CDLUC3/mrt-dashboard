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

def response_assembly_200(token = SecureRandom.uuid, ready = 20)
  # set expiration a few seconds in the future
  time = Time.new.gmtime + ready
  {
    status: 200,
    token: token,
    'cloud-content-byte': 12_345,
    'anticipated-availability-time': time.strftime('%Y-%m-%dT%H:%M:%S%z'),
    message: 'Request queued, use token to check status'
  }
end

def response_token_200(token = 'uuid', url = 'http://cdl.org/demo.zip')
  {
    status: 200,
    message: 'Payload contains token info',
    token: token,
    'cloud-content-byte': 12_345,
    url: url
  }
end

def response_token_202(token = 'uuid')
  {
    status: 202,
    token: token,
    'anticipated-size': 12_345,
    'anticipated-availability-time': '2009-06-15T13:45:30',
    message: 'object is not ready'
  }
end

def response_token_410(token = 'uuid')
  {
    status: 410,
    token: token,
    'anticipated-size': 12_345,
    'expiration-time': '2009-06-15T13:45:30',
    message: 'signed url has expired'
  }
end

def general_response_404
  {
    status: 404,
    message: 'Object not found'
  }
end

def general_response_403
  {
    status: 403,
    # 'Object content is in offline storage, request is not supported'
    # 'Invalid assembly node for presigned delivery'
    message: 'Not supported'
  }
end

def general_response_500
  {
    status: 500,
    message: 'error message'
  }
end

def mock_assembly(node_id, key, json, params = {})
  client = mock_httpclient
  nk = {
    node_id: node_id,
    key: key
  }
  expect(client).to receive(:post).with(
    ApplicationController.get_storage_presign_url(nk, false, params),
    follow_redirect: true
  ).and_return(
    mock_response(
      json[:status], json[:message], json
    )
  )
end
