# rubocop:disable Metrics/AbcSize
module NumberMixin
  # Modeled after the rails helper that does all sizes in binary representations
  # but gives sizes in decimal instead with 1kB = 1,000 Bytes, 1 MB = 1,000,000 bytes
  # etc.
  #
  # Formats the bytes in +size+ into a more understandable representation.
  # Useful for reporting file sizes to users. This method returns nil if
  # +size+ cannot be converted into a number. You can change the default
  # precision of 1 in +precision+.
  #
  #  number_to_storage_size(123)           => 123 Bytes
  #  number_to_storage_size(1234)          => 1.2 kB
  #  number_to_storage_size(12345)         => 12.3 kB
  #  number_to_storage_size(1234567)       => 1.2 MB
  #  number_to_storage_size(1234567890)    => 1.2 GB
  #  number_to_storage_size(1234567890123) => 1.2 TB
  #  number_to_storage_size(1234567, 2)    => 1.23 MB
  def number_to_storage_size(size, precision = 1)
    size = Kernel.Float(size)
    if size == 1 then '1 Byte'
    elsif size < 10**3 then format('%d B', size)
    elsif size < 10**6 then format("%.#{precision}f KB", (size / 10.0**3))
    elsif size < 10**9 then format("%.#{precision}f MB", (size / 10.0**6))
    elsif size < 10**12 then format("%.#{precision}f GB", (size / 10.0**9))
    else format("%.#{precision}f TB", (size / 10.0**12))
    end.sub('.0', '')
  rescue StandardError
    nil
  end
end
# rubocop:enable Metrics/AbcSize
