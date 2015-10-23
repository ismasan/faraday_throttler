require 'faraday'
require 'faraday_throttler/key_resolver'
require 'faraday_throttler/mem_lock'
require 'faraday_throttler/cache'
require 'faraday_throttler/fallbacks'

module FaradayThrottler

  class Middleware < Faraday::Middleware
    def initialize(app, lock: MemLock.new, cache: Cache.new, key_resolver: KeyResolver.new, rate: 10, fallbacks: Fallbacks.new)
      validate_dep! lock, :lock, :set
      validate_dep! cache, :cache, :get, :set
      validate_dep! key_resolver, :key_resolver, :call
      validate_dep! fallbacks, :fallbacks, :call

      @lock = lock
      @cache = cache
      @key_resolver = key_resolver
      @rate = rate
      @fallbacks = fallbacks
      super app
    end

    def call(request_env)
      return app.call(request_env) if request_env[:method] != :get

      start = Time.now

      key = key_resolver.call(request_env)

      if lock.set(key, rate)
        app.call(request_env).on_complete do |response_env|
          cache.set key, response_env
        end
      else
        if cached_response = cache.get(key)
          resp cached_response, :cached, start
        else
          resp fallbacks.call(request_env), :fallback, start
        end
      end
    end

    private
    attr_reader :app, :lock, :cache, :key_resolver, :rate, :fallbacks

    def resp(resp_env, status = :fresh, start = Time.now)
      resp_env = Faraday::Env.from(resp_env)
      resp_env[:response_headers].merge!(
        'X-Throttler' => status.to_s,
        'X-ThrottlerTime' => (Time.now - start)
      )

      ::Faraday::Response.new(resp_env)
    end

    def validate_dep!(dep, dep_name, *methods)
      methods.each do |m|
        raise ArgumentError, %(#{dep_name} must implement :#{m}) unless dep.respond_to?(m)
      end
    end
  end

end
