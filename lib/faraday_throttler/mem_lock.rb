module FaradayThrottler
  class MemLock
    def initialize
      @locks = {}
      @mutex = Mutex.new
    end

    def set(key, ttl = 30)
      mutex.synchronize {
        now = Time.now
        exp = locks[key]

        if !exp || exp < now
          locks[key] = now + ttl
          return true
        else
          return false
        end
      }
    end

    private
    attr_reader :locks, :mutex

  end
end
