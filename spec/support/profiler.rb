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

# rubocop:disable Metrics/ClassLength
class Profiler
  attr_reader :report_format, :times_started, :times_elapsed, :time_stopped, :rp_result

  def initialize(report_format)
    @report_format = report_format
    @times_started = {}
    @times_elapsed = {}
  end

  def start(_n10n)
    return unless use_rubyprof?

    puts 'Starting RubyProf'
    profile.start
  end

  def profile
    @profile ||= begin
      profile = RubyProf::Profile.new
      profile.exclude_common_methods!
      puts "Excluding methods from the following modules and all children: #{excludes}"
      excludes.flat_map { |m| all_modules(m) }.each do |m|
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
      ActionController,
      ActiveSupport::Dependencies,
      BasicObject,
      Capybara,
      DatabaseCleaner,
      Enumerator,
      Kernel,
      Puma,
      RSpec,
      Sprockets,
      Thread,
      WebMock
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
    parent_name = mod.name =~ /::[^:]+\Z/ ? Regexp.last_match.pre_match.freeze : nil
    Object.const_get(parent_name) if parent_name
  end

  def all_modules(mod)
    [mod] + mod.constants.map { |c| to_const(mod, c) }
      .compact
      .select { |c| c.is_a?(Module) && parent_of(c) == mod }
      .flat_map { |m| all_modules(m) }
  end

  def to_const(parent, const_name)
    parent.const_get(const_name)
  rescue LoadError
    # we're loading everything unconditionally, & sometimes it doesn't work
  end

  def print_report_calltree!
    print "\nWriting calltree/cachegrind profile report to #{calltree_output_path}..."
    printer = RubyProf::CallTreePrinter.new(rp_result)
    printer.print(path: calltree_output_path)
    Dir[output_dir]
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
      profile_path = "#{project_root_path}profile"
      FileUtils.mkdir_p(profile_path.to_s)
      profile_path
    end
  end

  def calltree_output_path
    @calltree_output_path ||= begin
      ct_path = output_dir.realpath + "profile-#{time_stopped.to_i}"
      FileUtils.mkdir_p(ct_path.to_s)
      ct_path
    end
  end

  def html_output_path
    @html_output_path ||= "#{output_dir.realpath}index.html"
  end

  def desc(n10n)
    example = n10n.example
    md = example.metadata
    path = md[:file_path].sub(%r{^\./}, '')
    line_number = md[:line_number].to_s.ljust(3)
    "#{path}:#{line_number}\t#{example.full_description}"
  end

end
# rubocop:enable Metrics/ClassLength
