require 'rails_helper'
require 'merritt/atom'

module Merritt
  module Atom
    describe Util do
      attr_reader :util

      before(:each) do
        @util = begin
          util = Object.new
          util.extend Util
          util
        end
      end

      describe :to_uri do
        it 'parses a URL' do
          url = 'http://example.org/'
          expected = URI.parse(url)
          expect(util.to_uri(url)).to eq(expected)
        end

        it 'parses URLs with spaces' do
          url = 'http://example.org/I have some spaces'
          expected = URI.parse(url.gsub(' ', '%20'))
          expect(util.to_uri(url)).to eq(expected)
        end

        it 'parses URLs with brackets' do
          url = 'http://example.org/[help_I_am_trapped_in_some_brackets]'
          expected = URI.parse(url.gsub('[', '%5B').gsub(']', '%5D'))
          expect(util.to_uri(url)).to eq(expected)
        end
      end

    end
  end
end
