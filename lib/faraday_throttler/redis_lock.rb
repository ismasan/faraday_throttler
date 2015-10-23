module FaradayThrottler
  class RedisLock
    NAMESPACE = 'throttler:lock:'.freeze

    def initialize(redis = Redis.new)
      @redis = redis
    end

    def set(key, ttl = 30)
      redis.set([NAMESPACE, key].join, '1', ex: ttl, nx: true)
    end

    private
    attr_reader :redis
  end
end
