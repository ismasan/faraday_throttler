module FaradayThrottler
  class MemLock
    def initialize
      @locks = {}
    end

    def set(key, ttl = 30)
      now = Time.now
      exp = locks[key]

      if !exp || exp < now
        locks[key] = now + ttl
        return true
      else
        return false
      end
    end

    private
    attr_reader :locks

  end
end
