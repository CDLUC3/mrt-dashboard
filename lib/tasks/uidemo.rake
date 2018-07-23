require 'fileutils'
require 'open3'
require 'pathname'

class UIDemo
  attr_reader :project_root_path

  def initialize(project_root)
    @project_root_path = Pathname.new(project_root)
  end

  def compile_demo!
    raise 'Can’t process SCSS without sass or sassc' unless sass_cmd
    raise "Can’t locate UI library #{ui_library_path}" unless ui_library_path.exist?
    clear_demo_dir!
    process_source_files!
  end

  private

  def sass_cmd
    @sass_cmd ||= if system('which sassc > /dev/null 2>&1')
                    'sassc -t expanded'
                  elsif system('which sass > /dev/null 2>&1')
                    'sass'
                  end
  end

  def ui_library_path
    @ui_library_path ||= project_root_path + 'ui-library'
  end

  def ui_library_path_str
    ui_library_path.to_s
  end

  def demo_path
    @demo_path ||= project_root_path + 'public/demo'
  end

  def demo_path_str
    @demo_path_str ||= demo_path.to_s
  end

  def clear_demo_dir!
    puts "Clearing #{demo_path.relative_path_from(project_root_path)}"
    FileUtils.remove_dir(demo_path_str) if File.directory?(demo_path_str)
  end

  def process_source_files!
    puts "Processing source files from #{ui_library_path.relative_path_from(project_root_path)}"
    Dir.glob("#{ui_library_path}/**/*").each do |infile|
      next if File.directory?(infile)
      process_file(infile)
    end
  end

  def process_file(infile)
    infile.end_with?('.scss') ? compile_scss(infile) : copy_to_demo(infile)
  end

  def compile_scss(infile)
    outfile = infile.sub(ui_library_path_str, demo_path_str).gsub('scss', 'css')
    ensure_parent(outfile)
    puts "Compiling #{infile} to #{outfile}"
    _, stderr, status = Open3.capture3("#{sass_cmd} '#{infile}' > '#{outfile}'")
    raise IOError, stderr unless status == 0
  end

  def copy_to_demo(infile)
    outfile = infile.sub(ui_library_path_str, demo_path_str)
    ensure_parent(outfile)
    puts "Copying #{infile} to #{outfile}"
    FileUtils.cp(infile, outfile)
  end

  def ensure_parent(outfile)
    FileUtils.mkdir_p(File.expand_path('..', outfile))
  end
end

task :uidemo do
  project_root = File.expand_path('../..', __dir__)
  UIDemo.new(project_root).compile_demo!
end
