require 'merritt/atom'

namespace :atom do
  desc 'Generic Atom to Merritt processor'
  task :update, Merritt::Atom::Harvester::ARG_KEYS => :environment do |_, task_args|
    arg_hash = task_args.to_h
    delay, batch_size = throttler(task_args.extras)
    args = arg_hash.merge(delay: delay.to_i, batch_size: batch_size.to_i)
    processor = Merritt::Atom::Harvester.new(args)
    processor.log_info("Initialized harvester: #{args.map { |k, v| "#{k}: #{v}" }.join(', ')}")
    processor.process_feed!
  end

  # Usage example:
  #
  # bundle exec rake atom:gen_csh['production',UCM Ramicova','https://s3.amazonaws.com/static.ucldc.cdlib.org/merritt/ucldc_collection_26098.atom','ucm_lib_nuxeo','ark:/13030/m5b58sn8','Merced Library Nuxeo collection']
  desc 'Generate CSH script for Atom feed harvesting'
  task :gen_csh, Merritt::Atom::CSHGenerator::ARG_KEYS => :environment do |_, task_args|
    csh_source = Merritt::Atom::CSHGenerator.generate_csh(task_args.to_h)
    puts csh_source
  end

  # The CSV file should be in the format:
  #
  # environment,nuxeo_collection_name,feed_url,merritt_collection_mnemonic,merritt_collection_ark,merritt_collection_name
  #
  # Usage example:
  #
  # bundle exec rake atom:csv_to_csh[/tmp/feeds.csv,../mrt-dashboard-config/atom/bin]
  desc 'Read the specified CSV file and write Atom feed harvest scripts to the specified directory'
  task :csv_to_csh, %i[csv_file to_dir] => :environment do |_, task_args|
    csv_data = File.read(task_args[:csv_file])
    to_dir = task_args[:to_dir]
    count = Merritt::Atom::CSHGenerator.from_csv(csv_data: csv_data, to_dir: to_dir)
    target_dir = File.realpath(to_dir)
    puts "Wrote #{count} CSH scripts to #{target_dir}"
  end

  def throttler(extras)
    return extras if extras.any?
    [Merritt::Atom::DEFAULT_DELAY, Merritt::Atom::DEFAULT_BATCH_SIZE]
  end
end
