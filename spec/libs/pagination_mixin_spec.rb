require 'rails_helper'

describe PaginationMixin do
  include PaginationMixin

  attr_reader :logger
  attr_reader :params

  before(:each) do
    @logger = instance_double(Logger)
    @params = {}
  end

  describe ':page_param' do
    it 'parses an int' do
      an_int = 17
      params[:page] = an_int.to_s
      expect(page_param).to eq(an_int)
    end

    it 'parses 0 as 1' do
      zero = 0.to_s
      params[:page] = zero
      expect(logger).to receive(:warn).once do |m|
        expect(m).to include(zero)
      end
      expect(page_param).to eq(1)
    end

    it 'parses negative number as 1' do
      negative = -17.to_s
      params[:page] = negative
      expect(logger).to receive(:warn).once do |m|
        expect(m).to include(negative)
      end
      expect(page_param).to eq(1)
    end

    it 'parses garbage as 1 and logs the error' do
      garbage = 'garbage'
      params[:page] = garbage
      expect(logger).to(receive(:error)).once do |m|
        expect(m).to include(garbage)
      end
      expect(page_param).to eq(1)
    end

    it 'handles previously parsed ints transparently' do
      an_int = 17
      params[:page] = an_int
      expect(page_param).to eq(an_int)
    end
  end
end
