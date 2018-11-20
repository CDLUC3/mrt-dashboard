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

class ProfilingReporter
  attr_reader :times_started
  attr_reader :times_elapsed
  attr_reader :time_stopped
  attr_reader :rp_result

  def start(_n10n)
    RubyProf.start
  end

  def stop(_n10n)
    @time_stopped = Time.now
    @rp_result = RubyProf.stop
  end

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

    print_report_html!
    # print_report_calltree!
  end

  private

  # TODO: figure out how to configure this to produce reasonable filenames
  # TODO: find a free tool that can display this output in a reasonable way
  def print_report_calltree!
    print "\nWriting calltree/qcachegrind profile report to #{output_dir} ..."
    printer = RubyProf::CallTreePrinter.new(rp_result)
    printer.print(path: output_dir, profile: 'cachegrind.out')
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
    @html_output_path ||= begin
      (output_dir + 'index.html').realpath
    end
  end

  def desc(n10n)
    example = n10n.example
    md = example.metadata
    path = md[:file_path].sub(%r{^\./}, '')
    line_number = md[:line_number].to_s.ljust(3)
    "#{path}:#{line_number}\t#{example.full_description}"
  end

end
