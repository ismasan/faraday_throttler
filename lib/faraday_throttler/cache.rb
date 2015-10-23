module FaradayThrottler
  class Cache
    def initialize(store = {})
      @mutex = Mutex.new
      @store = store
    end

    def set(key, resp)
      mutex.synchronize { store[key] = resp }
    end

    def get(key, wait = 0)
      r = mutex.synchronize { store[key] }
      return r if wait == 0
      sleep wait
      mutex.synchronize { store[key] }
    end

    private
    attr_reader :store, :mutex
  end
end
