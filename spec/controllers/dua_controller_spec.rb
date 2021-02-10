require 'rails_helper'

class Openable
  def initialize(data)
    @data = data
  end

  def open(*_rest)
    io = StringIO.new(@data, 'r')
    return io unless block_given?

    yield io
  end
end

describe DuaController do
  describe ':with_fetched_tempfile' do
    attr_reader :data

    before(:each) do
      # We don't really care what the data is so long as we can read/write it in text mode
      @data = SecureRandom.hex(5000).freeze
    end

    it 'copies an arbitrary openable to a tempfile' do
      contents = nil
      controller.send(:with_fetched_tempfile, Openable.new(data)) do |tmp_file|
        contents = tmp_file.read
      end
      expect(contents).to eq(data)
    end

    it 'copies a file to a tempfile' do
      bytes_file = Tempfile.new(%w[foo bin])
      bytes_file.write(data)
      bytes_file.close
      bytes_file_path = File.expand_path(bytes_file.path)

      begin
        contents = nil
        controller.send(:with_fetched_tempfile, bytes_file_path) do |tmp_file|
          contents = tmp_file.read
        end
        expect(contents).to eq(data)
      ensure
        File.delete(bytes_file_path)
      end
    end
  end
end
