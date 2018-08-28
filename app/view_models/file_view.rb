class FileView
  attr_reader :file
  attr_reader :vc

  def self.producer_files(version, view_context)
    version.producer_files.quickload_files.lazy.map { |f| FileView.new(f, view_context) }
  end

  def self.system_files(version, view_context)
    version.system_files.quickload_files.lazy.map { |f| FileView.new(f, view_context) }
  end

  def initialize(inv_file, view_context)
    @file = inv_file
    @vc = view_context
  end

  def pathname
    @pathname ||= file.pathname
  end

  def dirname
    return @dirname if defined?(@dirname)
    @dirname ||= begin
      name = File.dirname(pathname).sub(%r{^(producer|system)/?}, '')
      name.blank? ? nil : name
    end
  end

  def basename
    @basename ||= File.basename(pathname)
  end

  def exceeds_download_size?
    @exceeds_download_size ||= file.exceeds_download_size?
  end

  def to_param
    @as_param ||= file.to_param
  end

  def mime_type
    @mime_type ||= vc.clean_mime_type(file.mime_type)
  end

  def size
    @size ||= vc.number_to_storage_size(file.full_size)
  end

end
