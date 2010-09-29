module Mrt
  class Cache
    def self.cache(key, expires_in = 600)
      begin
        retval = Rails.cache.read(key)
        if retval.nil? then
          retval = yield()
          Rails.cache.write(key, retval, :expires_in=>expires_in)
        end
        return retval
      rescue ArgumentError
      ensure
        # Problem storing in cache, just return the yielded value.
      end
      return yield()
    end
  end
end
