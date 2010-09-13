require 'ftools'

class DataFile < ActiveRecord::Base
  def self.save(upload, userid)
    name =  upload.original_filename
    directory = "public/data/#{userid}"
    # create the file path
    path = File.join(directory, name)
    #create the directory if needed
    File.makedirs(directory) if !File.directory?(directory)
    # write the file
    File.open(path, "wb") { |f| f.write(upload.read) }
    path
  end

end
