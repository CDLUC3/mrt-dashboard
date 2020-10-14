require 'rails_helper'
require 'webmock/rspec'

describe LostorageController do
  attr_reader :client
  attr_reader :post_email_response

  attr_reader :object
  attr_reader :object_ark
  attr_reader :version_number

  attr_reader :user_id
  attr_reader :params

  attr_reader :object_page_url

  def mock_client!
    @client = instance_double(HTTPClient)
    allow(HTTPClient).to receive(:new).and_return(client)
    allow(client).to receive(:follow_redirect_count).and_return(10)
    %i[receive_timeout= send_timeout= connect_timeout= keep_alive_timeout=].each do |m|
      allow(client).to receive(m)
    end
  end

  before(:each) do
    @object = create(:inv_object, erc_who: 'Doe, Jane', erc_what: 'Object 1', erc_when: '2018-01-01')
    @object_ark = object.ark
    @version_number = object.current_version.number

    @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

    @params = { object: @object_ark, version: @version_number, userFriendly: 'false', user_agent_email: 'jdoe@example.edu' }
    @object_page_url = controller.mk_merritt_url('m', object_ark, version_number)
  end

  describe ':index' do
    before(:each) do
      mock_client!
      params.merge!(commit: 'Submit')
    end

    it 'requires a user' do
      @request.headers['HTTP_AUTHORIZATION'] = nil
      request.session.merge!({ uid: nil })
      post(:index, params: params)
      expect(response.code.to_i).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'requires an email address' do
      expect(client).not_to receive(:post)
      params.delete(:user_agent_email)
      request.session.merge!({ uid: user_id })
      post(:index, params: params)
      expect(flash[:message]).to be_present
    end

    it 'requires a valid-ish address' do
      expect(client).not_to receive(:post)
      params[:user_agent_email] = params[:user_agent_email].tr('@', '%')
      request.session.merge!({ uid: user_id })
      post(:index, params: params)
      expect(flash[:message]).to be_present
    end

    it 'requires a successful email post' do
      @post_email_response = instance_double(HTTP::Message)
      allow(post_email_response).to receive(:status).and_return(500)
      allow(client).to receive(:post).and_return(post_email_response)

      request.session.merge!({ uid: user_id })
      post(:index, params: params)
      expect(flash[:error]).to include('uc3@ucop.edu')
    end

    it 'can be canceled' do
      params[:commit] = 'Cancel'
      expect(client).not_to receive(:post)
      request.session.merge!({ uid: user_id })
      post(:index, params: params)
      expect(flash[:message]).not_to be_present
    end

    describe 'success' do

      before(:each) do
        @post_email_response = instance_double(HTTP::Message)
        allow(post_email_response).to receive(:status).and_return(200)
        allow(client).to receive(:post).and_return(post_email_response)
      end

      it 'emails the user' do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <email>
            <from>marisa.strong@ucop.edu</from>
            <to>jdoe@example.edu</to>
            <bcc>marisa.strong@ucop.edu</bcc>
            <subject>Merritt Version Download Processing Completed</subject>
            <msg/>
          </email>
        XML

        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)

          email_xml_file = post_params['email']
          expect(email_xml_file).not_to be_nil
          email_xml = email_xml_file.read
          expect(email_xml).to be_xml(expected_xml)
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
      end

      it 'allows a custom from address' do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <email>
            <from>merritt@example.edu</from>
            <to>jdoe@example.edu</to>
            <bcc>marisa.strong@ucop.edu</bcc>
            <subject>Merritt Version Download Processing Completed</subject>
            <msg/>
          </email>
        XML

        params[:losFrom] = 'merritt@example.edu'
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)

          email_xml_file = post_params['email']
          expect(email_xml_file).not_to be_nil
          email_xml = email_xml_file.read
          expect(email_xml).to be_xml(expected_xml)
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
      end

      it 'allows a custom message body' do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <email>
            <from>marisa.strong@ucop.edu</from>
            <to>jdoe@example.edu</to>
            <bcc>marisa.strong@ucop.edu</bcc>
            <subject>Merritt Version Download Processing Completed</subject>
            <msg>Help I am trapped in a digital repository</msg>
          </email>
        XML

        params[:losBody] = 'Help I am trapped in a digital repository'
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)

          email_xml_file = post_params['email']
          expect(email_xml_file).not_to be_nil
          email_xml = email_xml_file.read
          expect(email_xml).to be_xml(expected_xml)
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
      end

      it 'sets the subject differently for full objects' do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <email>
            <from>marisa.strong@ucop.edu</from>
            <to>jdoe@example.edu</to>
            <bcc>marisa.strong@ucop.edu</bcc>
            <subject>Merritt Object Download Processing Completed</subject>
            <msg/>
          </email>
        XML

        params.delete(:version)
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)

          email_xml_file = post_params['email']
          expect(email_xml_file).not_to be_nil
          email_xml = email_xml_file.read
          expect(email_xml).to be_xml(expected_xml)
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
      end

      it 'allows a custom subject' do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <email>
            <from>marisa.strong@ucop.edu</from>
            <to>jdoe@example.edu</to>
            <bcc>marisa.strong@ucop.edu</bcc>
            <subject>Help I am trapped in a digital repository</subject>
            <msg/>
          </email>
        XML

        params[:losSubject] = 'Help I am trapped in a digital repository'
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)

          email_xml_file = post_params['email']
          expect(email_xml_file).not_to be_nil
          email_xml = email_xml_file.read
          expect(email_xml).to be_xml(expected_xml)
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
      end

      it 'redirects back to the object' do
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
        expect(response.code.to_i).to eq(302)
        expect(response.headers['Location']).to end_with(object_page_url)
      end

      it 'uses the producer URL for "user friendly" download' do
        expected_xml = <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <email>
            <from>marisa.strong@ucop.edu</from>
            <to>jdoe@example.edu</to>
            <bcc>marisa.strong@ucop.edu</bcc>
            <subject>Merritt Version Download Processing Completed</subject>
            <msg/>
          </email>
        XML

        params[:userFriendly] = 'true'
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri2.to_s.gsub(/producer/, 'producerasync') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)

          email_xml_file = post_params['email']
          expect(email_xml_file).not_to be_nil
          email_xml = email_xml_file.read
          expect(email_xml).to be_xml(expected_xml)
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:index, params: params)
      end
    end

  end

  describe ':direct' do
    before(:each) do
      mock_client!
    end

    it 'requires an email address' do
      expect(client).not_to receive(:post)
      params.delete(:user_agent_email)
      request.session.merge!({ uid: user_id })
      post(:direct, params: params)
      expect(response.status).to eq(406)
    end

    it 'requires a valid-ish address' do
      expect(client).not_to receive(:post)
      params[:user_agent_email] = params[:user_agent_email].tr('@', '%')
      request.session.merge!({ uid: user_id })
      post(:direct, params: params)
      expect(response.status).to eq(400)
    end

    it 'requires a successful email post' do
      @post_email_response = instance_double(HTTP::Message)
      allow(post_email_response).to receive(:status).and_return(500)
      allow(client).to receive(:post).and_return(post_email_response)
      request.session.merge!({ uid: user_id })
      post(:direct, params: params)
      expect(response.status).to eq(503)
    end

    describe ':success' do
      before(:each) do
        @post_email_response = instance_double(HTTP::Message)
        allow(post_email_response).to receive(:status).and_return(200)
      end

      it 'can succeed' do
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)
          email_xml = post_params['email']
          expect(email_xml).not_to be_nil # TODO: rewrite post_los_email so we don't pass live file pointers around & can actually test
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:direct, params: params)
        expect(response.status).to eq(200)
      end

      it 'uses the producer URL for "user friendly" download' do
        params[:userFriendly] = 'true'
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri2.to_s.gsub(/producer/, 'producerasync') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)
          email_xml = post_params['email']
          expect(email_xml).not_to be_nil # TODO: rewrite post_los_email so we don't pass live file pointers around & can actually test
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:direct, params: params)
        expect(response.status).to eq(200)
      end

      it 'defaults to user-friendly' do
        params[:userFriendly] = nil
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri2.to_s.gsub(/producer/, 'producerasync') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)
          email_xml = post_params['email']
          expect(email_xml).not_to be_nil # TODO: rewrite post_los_email so we don't pass live file pointers around & can actually test
        end.and_return(post_email_response)
        request.headers.merge!({ 'Content-Type' => 'multipart/form-data' })
        request.session.merge!({ uid: user_id })
        post(:direct, params: params)
        expect(response.status).to eq(200)
      end
    end
  end

  describe ':do_storage_post' do
    attr_reader :async_url

    def redirect_url
      @redirect_url ||= begin
        uri = URI.parse(async_url)
        uri.host = 'store01.merritt.example.edu'
        uri.port = 12_345
        uri.to_s
      end
    end

    before(:each) do
      WebMock.disable_net_connect!
      @async_url = object.bytestream_uri.to_s.gsub(/content/, 'async')
      stub_request(:post, async_url).to_return(status: 307, headers: { Location: redirect_url })
      stub_request(:post, redirect_url).to_return(status: 200, body: post_email_response)
      controller.instance_variable_set(:@object, object)
    end

    after(:each) do
      WebMock.allow_net_connect!
    end

    it 'follows redirects' do
      resp = nil
      Tempfile.create('mail.xml') do |email_xml_file|
        user_friendly = false
        to_addr = params[:user_agent_email]
        unique_name = "#{UUIDTools::UUID.random_create.hash}.tar.gz"
        resp = controller.send(:do_storage_post, email_xml_file, to_addr, unique_name, user_friendly)
      end
      status = resp && resp.status
      expect(status).to eq(200)
    end
  end
end
