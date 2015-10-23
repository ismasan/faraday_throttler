module FaradayThrottler
  class Cache
    def initialize
      @store = {}
    end

    def set(key, resp)
      store[key] = resp
    end

    def get(key, wait = 0)
      store[key]
    end

    private
    attr_reader :store
  end
end
