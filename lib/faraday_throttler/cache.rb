require 'faraday_throttler/retryable'

module FaradayThrottler
  class Cache
    include Retryable

    def initialize(store = {})
      @mutex = Mutex.new
      @store = store
    end

    def set(key, resp)
      mutex.synchronize { store[key] = resp }
    end

    def get(key, wait = 0)
      with_retry(wait) {
        mutex.synchronize { store[key] }
      }
    end

    private
    attr_reader :store, :mutex
  end
end
