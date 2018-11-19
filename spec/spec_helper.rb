require 'colorize'

# ------------------------------------------------------------
# SimpleCov

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.minimum_coverage 100
  SimpleCov.start 'rails'
end

# ------------------------------------------------------------
# Rudimentary performance profiling
# cf. https://www.foraker.com/blog/profiling-your-rspec-suite
require 'time'

class ProfilingReporter
  attr_reader :times_started
  attr_reader :times_elapsed

  def initialize
    @times_started = {}
    @times_elapsed = {}
  end

  def example_started(n10n)
    times_started[desc(n10n)] = Time.now
  end

  def example_finished(n10n)
    time_finished = Time.now
    description = desc(n10n)
    time_elapsed = (time_finished - times_started[description])
    times_elapsed[description] = time_elapsed
  end

  def dump_summary(_n10n)
    puts "\nTime(s)\tLocation\tExample"
    times_elapsed.sort_by(&:last).reverse_each do |desc, time_elapsed|
      puts "#{format('%.4f', time_elapsed)}\t#{desc}"
    end
  end

  private

  def desc(n10n)
    example = n10n.example
    md = example.metadata
    path = md[:file_path].sub(%r{^\./}, '')
    line_number = md[:line_number].to_s.ljust(3)
    "#{path}:#{line_number}\t#{example.full_description}"
  end

end

# ------------------------------------------------------------
# Rspec configuration

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  # config.raise_errors_for_deprecations! # TODO: enable this
  config.mock_with :rspec
  config.reporter.register_listener(ProfilingReporter.new, :dump_summary, :example_started, :example_finished)
end

require 'rspec_custom_matchers'

# ------------------------------------------------------------
# Rails

if (env = ENV['RAILS_ENV'])
  abort("Can't run tests in environment #{env}") if env != 'test'
else
  ENV['RAILS_ENV'] = 'test'
end
