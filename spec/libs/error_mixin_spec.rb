require 'rails_helper'

describe ErrorMixin do
  include ErrorMixin

  it 'handles nil' do
    expect(to_msg(nil)).to include(nil.class.to_s)
  end

  it 'handles raw strings' do
    str = 'a string'
    expect(to_msg(str)).to include(str)
  end

  it 'handles exceptions' do
    err_class = StandardError
    err_msg = 'Help I am trapped in a unit test'
    full_msg = nil
    begin
      raise err_class, err_msg
    rescue StandardError => e
      full_msg = to_msg(e)
    end
    expect(full_msg).to include(err_class.to_s)
    expect(full_msg).to include(err_msg)
    expect(full_msg).to include(__FILE__)
  end

  it 'handles nested exceptions' do
    inner_class = ArgumentError
    inner_msg = 'Help I am trapped in a nested exception'
    outer_class = StandardError
    outer_msg = 'Help I am a nested exception'
    full_msg = nil
    begin
      begin
        raise inner_class, inner_msg
      rescue StandardError
        raise outer_class, outer_msg
      end
    rescue StandardError => e
      full_msg = to_msg(e)
    end
    expect(full_msg).to include(inner_class.to_s)
    expect(full_msg).to include(inner_msg)
    expect(full_msg).to include(outer_class.to_s)
    expect(full_msg).to include(outer_msg)
    expect(full_msg).to include(__FILE__)
  end

end
