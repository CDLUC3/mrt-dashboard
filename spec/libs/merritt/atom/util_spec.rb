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

      describe :parse_time do
        it 'parses a time' do
          time_str = '2018-10-09T22:17:50.170356+00:00'
          expected = Time.utc(2018, 10, 9, 22, 17, 50.17)
          parsed = util.parse_time(time_str)
          expect(parsed).to be_time(expected)
          expect(parsed.gmt_offset).to eq(0)
        end

        it 'returns NEVER in the event of an error, if no default' do
          parsed = util.parse_time('I am not a time')
          expect(parsed).to eq(Util::NEVER)
        end

        it 'returns the specified default in the event of an error' do
          default = Time.now
          parsed = util.parse_time('I am not a time', default: default)
          expect(parsed).to eq(default)
        end
      end

      describe 'fallback logging' do
        before(:each) do
          allow(Rails).to receive(:logger).and_return(nil)
        end

        describe :log_info do
          it 'falls back to stdout' do
            msg = 'I am a info message'
            expect($stdout).to receive(:puts).with(msg)
            util.log_info(msg)
          end
        end

        describe :log_error do
          it 'falls back to Object#warn' do
            msg = 'I am an error message'
            expect(util).to receive(:warn).with(msg)
            util.log_error(msg)
          end
        end
      end

    end
  end
end
