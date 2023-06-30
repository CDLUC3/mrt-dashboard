class Downloads

  # ------------------------------------------------------------
  # Constants

  TIMEOUT = 5

  class << self
    # ------------------------------------------------------------
    # Accessors

    def dir
      @dir ||= Dir.mktmpdir('capybara-downloads')
    end

    def path
      @path ||= Pathname.new(dir)
    end

    def complete?
      return false if in_progress?

      any?
    end

    def in_progress?
      Pathname.glob("#{dir}/*.crdownload").any?
    end

    def any?
      all.any?
    end

    def all
      Pathname.glob("#{dir}/*").select(&:file?)
    end

    def first
      all.first
    end

    # ------------------------------------------------------------
    # Operations

    def wait_for_downloads!(timeout_secs = TIMEOUT)
      Timeout.timeout(timeout_secs) do
        sleep 0.1 until complete?
      end
    end

    def wait_for(count, timeout_secs = TIMEOUT)
      Timeout.timeout(timeout_secs) do
        sleep 0.1 while in_progress? || all.size < count
      end
    end

    def clear!
      return unless @dir && File.exist?(dir)

      files_to_remove = Dir.glob("#{dir}/*")
      puts "removing #{files_to_remove}"
      FileUtils.rm_rf(files_to_remove, secure: true)
    end

    def remove_directory!
      FileUtils.rm_rf(dir, secure: true)
    ensure
      @path = @dir = nil
    end
  end

end
