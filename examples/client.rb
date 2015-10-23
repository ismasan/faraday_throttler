require 'bundler/setup'
require 'redis'
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'faraday_throttler/middleware'
require 'faraday_throttler/redis_lock'
require 'faraday_throttler/redis_cache'


redis = Redis.new
lock = FaradayThrottler::RedisLock.new(redis)
cache = FaradayThrottler::RedisCache.new(redis: redis, ttl: 60)

conn = Faraday.new(:url => 'http://localhost:9292') do |faraday|
  # faraday.response :logger                  # log requests to STDOUT
  faraday.use :throttler, rate: 3, wait: 1, lock: lock, cache: cache
  faraday.adapter  Faraday.default_adapter
end


tr = (1..100).map do |i|
  Thread.new do
    sleep (rand * 10)
    n = Time.now
    r = conn.get('/foo/bar')
    puts %([#{n}] #{r.headers['X-Throttler']} took: #{r.headers['X-ThrottlerTime']} - #{r.body})
  end
end

tr.map{|t| t.join }

