require 'rails'
require_relative '../../config/initializers/config'
require_relative '../../app/lib/encoder'
require_relative '../../app/models/application_record'
require_relative '../../app/models/inv_collection'

# :nocov:
# rubocop:disable Metrics/AbcSize
class Terry
  def hello
    # Dir.glob("#{Rails.root}/app/models/*.rb").each { |file| require file }
    puts "hello from Terry #{Rails.env}"
    puts "hello from Terry #{Rails.root}"
    coll = InvCollection.where(mnemonic: 'ucsb_lib_etd').first
    puts coll.name
    File.open('out.csv', 'w') do |file|
      coll.recent_objects.each_with_index do |obj, i|
        file.write("#{i}\t#{obj.ark}\t#{obj.modified}\t#{obj.current_version.dk_who}\t#{obj.current_version.dk_what}\n")
      end
    end
  end
end

namespace :terry do
  desc 'test task'
  # Load Rails environment
  task hello: :environment do
    puts "SSM_ROOT_PATH: #{ENV.fetch('SSM_ROOT_PATH', nil)}"
    puts "RAILS_ENV: #{Rails.env}"
    if Rails.env && ENV.fetch('SSM_ROOT_PATH', nil)
      Terry.new.hello
    else
      puts 'Please set RAILS_ENV and SSM_ROOT_PATH'
    end
  end
end
# rubocop:enable Metrics/AbcSize
# :nocov:
