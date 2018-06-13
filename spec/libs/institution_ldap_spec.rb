require 'rails_helper'

module InstitutionLdap
  describe Server do
    attr_reader :inst_ldap

    before(:each) do
      @inst_ldap = Institution::LDAP
    end

    describe ':ns_dn' do
      it 'wraps the ID and appends the base' do
        id = 'foo'
        expected = "o=#{id},#{LDAP_CONFIG["inst_base"]}"
        expect(inst_ldap.ns_dn(id)).to eq(expected)
      end
    end

    describe ':obj_filter' do
      it 'creates a filter on the "o" field' do
        id = 'foo'
        expected = Net::LDAP::Filter.eq("o", id)
        filter = inst_ldap.obj_filter(id)
        expect(filter).to eq(expected)
      end
    end

  end
end
