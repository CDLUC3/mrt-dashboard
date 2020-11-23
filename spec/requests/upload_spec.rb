require "rails_helper"

RSpec.describe ObjectController, type: :request do

  before(:each) do
  end

  def create_filename(n)
    "/tmp/#{n}"
  end

  def create_file(path)
    File.open(path, 'w') do |f| 
      f.write("test") 
      f.close
    end
    File.join(path)
  end

  def upload_file(n)
    path = create_filename(n)
    f = create_file(path)
    @payload = {
      "file": f,
      "title": "title #{n}"
    }
    post "/object/upload", params: @payload.to_json
  end

  describe "POST /object/upload" do

    it 'Add README.md file' do
      upload_file('README.md')
    end

    it 'Add README %AF.md file' do
      upload_file('README %AF.md')
    end

  end

end