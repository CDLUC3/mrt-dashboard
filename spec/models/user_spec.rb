require 'rails_helper'

describe User do
  attr_reader :user
  attr_reader :user_ldap
  attr_reader :user_id
  attr_reader :password

  before(:each) do
    @password = 'correcthorsebatterystaple'
    @user_id = mock_user(name: 'Jane Doe', password: password)
    @user_ldap = User::LDAP.fetch(user_id)
    @user = User.new(user_ldap)
  end

  describe ':find_all' do
    it 'delegates to User::LDAP' do
      result = ['I am the test result']
      expect(User::LDAP).to receive(:find_all).and_return(result)
      expect(User.find_all).to eq(result)
    end
  end

  describe ':method_missing' do
    describe 'delegates to the ldap record' do
      it 'returns a non-array value as itself' do
        nonarray_result = Object.new
        nonarray_key = 'nonarray_key'
        user_ldap[nonarray_key] = nonarray_result
        expect(user.send(nonarray_key)).to eq(nonarray_result)
      end

      it 'unwraps a single-valued array' do
        singlevalue_result = [1]
        singlevalue_key = 'singlevalue_key'
        user_ldap[singlevalue_key] = singlevalue_result
        expect(user.send(singlevalue_key)).to eq(singlevalue_result[0])
      end

      it 'returns an entire multi-valued array' do
        multivalue_result = [1, 2, 3, 4]
        multivalue_key = 'multivalue_key'
        user_ldap[multivalue_key] = multivalue_result
        expect(user.send(multivalue_key)).to eq(multivalue_result)
      end
    end
  end

  describe ':valid_ldap_credentials' do
    it 'validates LDAP credentials' do
      expect(User.valid_ldap_credentials?(user_id, password)).to eq(true)
    end
  end
end
