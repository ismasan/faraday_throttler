require 'faraday_throttler/retryable'
require 'faraday_throttler/serializer'

module FaradayThrottler
  class RedisCache
    NAMESPACE = 'throttler:cache:'.freeze

    include Retryable

    def initialize(redis: Redis.new, ttl: 0, serializer: Serializer.new)
      @redis = redis
      @ttl = ttl
      @serializer = serializer
    end

    def set(key, resp)
      opts = {}
      opts[:ex] = ttl if ttl > 0
      redis.set [NAMESPACE, key].join, serializer.serialize(resp), opts
    end

    def get(key, wait = 10)
      with_retry(wait) {
        r = redis.get([NAMESPACE, key].join)
        r ? serializer.deserialize(r) : nil
      }  
    end

    private
    attr_reader :redis, :ttl, :serializer
  end
end
