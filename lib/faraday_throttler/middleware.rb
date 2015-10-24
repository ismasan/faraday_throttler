require 'timeout'
require 'faraday'
require 'faraday_throttler/key_resolver'
require 'faraday_throttler/mem_lock'
require 'faraday_throttler/cache'
require 'faraday_throttler/fallbacks'
require 'faraday_throttler/gauge'

module FaradayThrottler

  class Middleware < Faraday::Middleware
    def initialize(
        # The base Faraday adapter.
        app,

        # Request lock. This checks that only one unique request is in-flight at a given time.
        # Request uniqueness is defined by :lock_key_resolver.
        # Interface:
        #   #set(key String, ttl Integer)
        #
        # Returns _true_ if new lock aquired (no previous in-flight request)
        # Returns _false_ if no lock aquired (there is a current lock on an in-flight request).
        # MemLock is an in-memory lock. On a multi-threaded / multi-process environment
        # prefer the RedisLock implementation, which uses Redis as a distributed lock.
        lock: MemLock.new,

        # Response cache. Caches fresh responses from backend service,
        # so they can be used as a first fallback when connection exceeds :wait time.
        # Interface:
        #   #set(key String, response_env Hash)
        #   #get(key String, wait_seconds Integer)
        #
        # #get can implement polling/blocking behaviour
        # to wait for inflight-request to populate cache
        cache: Cache.new,

        # Resolves request unique key to use as lock
        # Interface:
        #   #call(request_env Hash) String
        lock_key_resolver: KeyResolver.new,

        # Resolves response unique key to use as cache key
        # Interface:
        #   #call(response_env Hash) String
        cache_key_resolver: KeyResolver.new,

        # Allow up to 1 request every 10 seconds, per path, to backend
        rate: 10,

        # Queued requests will wait for up to 5 seconds for current in-flight request
        # to the same path.
        # If in-flight request hasn't finished after that time, return a default placeholder response.
        wait: 5,

        # Wraps requests to backend service in a timeout block, in seconds.
        # If request takes longer than this:
        # * `gauge` receives #update(req_id, :timeout)
        # * Attempt to serve old response from cache. `gauge` receives #finish(req_id, :cached) if successful.
        # * If no cached response, delegate to fallbacks#call(request_env). `gauge` receives #finish(req_id, :fallback)
        # timeout: 0 disables this behaviour.
        timeout: 0,

        # Fallbacks resolver. Returns a fallback response when conection has waited over :wait time
        # for an in-flight response.
        # Use this to return sensible empty or error responses to your clients.
        # Interface:
        #   #call(request_env Hash) response_env Hash
        fallbacks: Fallbacks.new,

        # Gauge exposes #rate and #wait, to be used as TTL for lock and cache wait time.
        # The #start and #finish methods are called during a request/response cycle.
        # This should allow custom gauges to implement their own heuristic to calculate #rate and #wait on the fly.
        # By default a Null Gauge is used that just returns the values in the :rate and :wait arguments.
        # Interface:
        #   #rate(request_id String) Integer
        #   #wait(request_id String) Integer
        #   #start(request_id String, start_time Time)
        #   #update(request_id String, state Symbol)
        #   #finish(request_id String, state Symbol)
        #
        # `request_id` is the result of cache_key_resolver#call, normally an MD5 hash of the request full URL.
        # `state` can be one of :fresh, :cached, :timeout, :fallback
        gauge: nil
    )

      validate_dep! lock, :lock, :set
      validate_dep! cache, :cache, :get, :set
      validate_dep! lock_key_resolver, :lock_key_resolver, :call
      validate_dep! cache_key_resolver, :cache_key_resolver, :call
      validate_dep! fallbacks, :fallbacks, :call

      @lock = lock
      @cache = cache
      @lock_key_resolver = lock_key_resolver
      @cache_key_resolver = cache_key_resolver
      @rate = rate.to_i
      @wait = wait.to_i
      @timeout = timeout.to_i
      @fallbacks = fallbacks
      @gauge = gauge || Gauge.new(rate: @rate, wait: @wait)

      validate_dep! @gauge, :gauge, :start, :update, :finish

      super app
    end

    def call(request_env)
      return app.call(request_env) if request_env[:method] != :get

      start = Time.now

      lock_key = lock_key_resolver.call(request_env)
      cache_key = cache_key_resolver.call(request_env)

      gauge.start cache_key, start

      if lock.set(lock_key, gauge.rate(cache_key))
        begin
          with_timeout(timeout) {
            app.call(request_env).on_complete do |response_env|
              cache.set cache_key, response_env
              gauge.finish cache_key, :fresh
              debug_headers response_env, :fresh, start
            end
          }
        rescue ::Timeout::Error => e
          gauge.update cache_key, :timeout
          serve_from_cache_or_fallback request_env, cache_key, start
        end
      else
        serve_from_cache_or_fallback request_env, cache_key, start
      end
    end

    private
    attr_reader :app, :lock, :cache, :lock_key_resolver, :cache_key_resolver, :rate, :wait, :timeout, :fallbacks, :gauge

    def serve_from_cache_or_fallback(request_env, cache_key, start)
      if cached_response = cache.get(cache_key, gauge.wait(cache_key))
        gauge.finish cache_key, :cached
        resp cached_response, :cached, start
      else
        gauge.finish cache_key, :fallback
        resp fallbacks.call(request_env), :fallback, start
      end
    end

    def resp(resp_env, status = :fresh, start = Time.now)
      resp_env = Faraday::Env.from(resp_env)
      debug_headers resp_env, status, start
      ::Faraday::Response.new(resp_env)
    end

    def validate_dep!(dep, dep_name, *methods)
      methods.each do |m|
        raise ArgumentError, %(#{dep_name} must implement :#{m}) unless dep.respond_to?(m)
      end
    end

    def debug_headers(resp_env, status, start)
      resp_env[:response_headers].merge!(
        'X-Throttler' => status.to_s,
        'X-ThrottlerTime' => (Time.now - start)
      )
    end

    def with_timeout(seconds, &block)
      if seconds == 0
        yield
      else
        ::Timeout.timeout(seconds, &block)
      end
    end
  end

  Faraday::Middleware.register_middleware throttler: ->{ Middleware }
end
