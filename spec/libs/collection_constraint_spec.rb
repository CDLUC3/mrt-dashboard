require 'rails_helper'

describe CollectionConstraint do
  attr_reader :constraint
  attr_reader :request
  attr_reader :params

  before(:each) do
    @constraint = CollectionConstraint.new
    @request = instance_double(ActionDispatch::Request)
    @params = {}
    allow(request).to receive(:params).and_return(params)
  end

  describe ':matches?' do
    it 'returns false if no group provided' do
      expect(constraint.matches?(request)).to eq(false)
    end

    it 'returns true if group doesn\'t start with "ark"' do
      group_id = 'definitely not an ARK'
      params[:group] = group_id
      expect(constraint.matches?(request)).to eq(true)
    end

    it 'returns true for an ARK if we find a matching group' do
      group_ark = 'ark:/whatever'
      mock_collection(name: 'whatever', id: 'whatever_id', ark: group_ark)

      params[:group] = group_ark
      expect(constraint.matches?(request)).to eq(true)
    end

    it 'returns false for an ARK if we don\'t find a matching group' do
      group_id = 'ark:/whatever'
      params[:group] = group_id
      expect(Group).to receive(:find).and_raise(LdapMixin::LdapException)
      expect(constraint.matches?(request)).to eq(false)
    end
  end
end
