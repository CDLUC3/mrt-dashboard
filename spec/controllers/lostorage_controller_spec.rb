require 'rails_helper'

describe LostorageController do
  attr_reader :client
  attr_reader :post_email_response

  attr_reader :object
  attr_reader :object_ark
  attr_reader :version_number

  attr_reader :user_id
  attr_reader :params

  before(:each) do
    @client = instance_double(HTTPClient)
    allow(HTTPClient).to receive(:new).and_return(client)

    @post_email_response = instance_double(HTTP::Message)
    allow(post_email_response).to receive(:status).and_return(200)
    allow(client).to receive(:post).and_return(post_email_response)

    @object = create(:inv_object, erc_who: 'Doe, Jane', erc_what: "Object 1", erc_when: "2018-01-01")
    @object_ark = object.ark
    @version_number = object.current_version.number

    @user_id = mock_user(name: 'Jane Doe', password: 'correcthorsebatterystaple')

    @params = {object: @object_ark, version: @version_number, userFriendly: 'false'}
  end

  describe ':index' do
    before(:each) do
      params.merge!(commit: 'Submit', user_agent_email: 'jdoe@example.edu')
    end

    it 'requires a user' do
      @request.headers['HTTP_AUTHORIZATION'] = nil
      post(:index, params, {uid: nil})
      expect(response.code.to_i).to eq(302)
      expect(response.headers['Location']).to include('guest_login')
    end

    it 'requires an email address' do
      expect(client).not_to receive(:post)

      params.delete(:user_agent_email)
      post(:index, params, {uid: user_id})

      expect(flash[:message]).to be_present
    end

    it 'requires a valid-ish address' do
      expect(client).not_to receive(:post)

      params[:user_agent_email] = params[:user_agent_email].gsub('@', '%')
      post(:index, params, {uid: user_id})

      expect(flash[:message]).to be_present
    end

    describe 'success' do

      it 'emails the user' do
        expect(client).to receive(:post) do |url, post_params|
          async_url = object.bytestream_uri.to_s.gsub(/content/, 'async') # TODO: maybe just put this on the object?
          expect(url).to eq(async_url)
          email_xml = post_params['email']
          expect(email_xml).not_to be_nil # TODO: rewrite post_los_email so we don't pass live file pointers around & can actually test
        end.and_return(post_email_response)

        post(:index, params, {uid: user_id})
      end

      it 'redirects back to the object' do
        post(:index, params, {uid: user_id})
        expect(response.code.to_i).to eq(302)
        expected_url = controller.mk_merritt_url('m', object_ark, version_number)
        expect(response.headers['Location']).to end_with(expected_url)
      end
    end
  end
end
