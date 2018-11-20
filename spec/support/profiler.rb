# ------------------------------------------------------------
# Rudimentary performance profiling
# cf. https://www.foraker.com/blog/profiling-your-rspec-suite
require 'ruby-prof'
require 'time'

class ProfilePrinter < RubyProf::CallStackPrinter
  def print_css
    super
    css = <<~CSS_HTML
      <style>
        body {
          font-family: sans-serif;
          font-size: medium;
          line-height: 1.2em; // hmm
        }
        #help {
          font-size: smaller;
        }
        li {
          margin: 5px;
        }
        a.toggle {
          margin: 3px;
        }
      </style>
    CSS_HTML
    @output.puts(css)
  end
end

class Profiler
  attr_reader :report_format
  attr_reader :times_started
  attr_reader :times_elapsed
  attr_reader :time_stopped
  attr_reader :rp_result

  def initialize(report_format)
    @report_format = report_format
    @times_started = {}
    @times_elapsed = {}
  end

  def start(_n10n)
    if use_rubyprof?
      puts 'Starting RubyProf'
      profile.start
    end
  end


  def profile
    @profile ||= begin
      profile = RubyProf::Profile.new
      profile.exclude_common_methods!
      puts "Excluding methods from the following modules and all children: #{excludes}"
      excludes.flat_map {|m| all_modules(m) }.each do |m|
        methods = m.instance_methods + m.private_instance_methods
        profile.exclude_methods!(m, methods)
      end
      profile
    end
  end

  def stop(_n10n)
    @time_stopped = Time.now
    @rp_result = profile.stop if use_rubyprof?
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

    print_report_html! if html
    print_report_calltree! if calltree
  end

  private

  def excludes
    # can't make this a constant b/c they haven't all been loaded
    @excludes ||= [
      ActiveSupport::Dependencies,
      BasicObject,
      DatabaseCleaner,
      Kernel,
      RSpec
    ]
  end

  def html
    report_format == 'html'
  end

  def calltree
    report_format == 'calltree'
  end

  def use_rubyprof?
    html || calltree
  end

  def parent_of(mod)
    parent_name = mod.name =~ /::[^:]+\Z/ ? $`.freeze : nil
    Object.const_get(parent_name) if parent_name
  end

  def all_modules(mod)
    [mod] + mod.constants.map { |c| mod.const_get(c) }
              .select { |c| c.is_a?(Module) && parent_of(c) == mod }
              .flat_map { |m| all_modules(m) }
  end

  def print_report_calltree!
    base_name = "profile"
    print "\nWriting calltree/cachegrind profile report to #{output_dir}/#{base_name}..."
    printer = RubyProf::CallTreePrinter.new(rp_result)
    printer.print(path: output_dir, profile: base_name)
    puts ' Done.'
  end

  def print_report_html!
    print "\nWriting HTML profile report to #{html_output_path} ..."
    File.open(html_output_path, 'w') do |f|
      printer = ProfilePrinter.new(rp_result)
      printer.print(f)
    end
    puts ' Done.'
  end

  def output_dir
    @output_dir ||= begin
      project_root_path = Pathname.new(File.expand_path('../..', __dir__))
      profile_path = project_root_path + 'profile'
      FileUtils.mkdir_p(profile_path.to_s)
      profile_path
    end
  end

  def html_output_path
    @html_output_path ||= output_dir.realpath + 'index.html'
  end

  def desc(n10n)
    example = n10n.example
    md = example.metadata
    path = md[:file_path].sub(%r{^\./}, '')
    line_number = md[:line_number].to_s.ljust(3)
    "#{path}:#{line_number}\t#{example.full_description}"
  end

end
