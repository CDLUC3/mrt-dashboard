require 'features_helper'

describe 'collections' do
  attr_reader :user_id
  attr_reader :password

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)
  end

end
