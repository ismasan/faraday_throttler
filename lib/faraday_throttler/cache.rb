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
      return r if r || wait == 0
      
      value = nil
      ticks = 0
      while ticks <= wait do
        Kernel.sleep 1 
        ticks += 1
        value = mutex.synchronize{ store[key] }
      end

      value
    end

    private
    attr_reader :store, :mutex
  end
end
