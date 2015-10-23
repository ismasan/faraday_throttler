require 'faraday'
require 'faraday_throttler/key_resolver'

module FaradayThrottler

  class Middleware < Faraday::Middleware
    def initialize(app, lock:, cache:, key_resolver: KeyResolver.new, rate: 10, wait: 3, fallbacks:)
      @lock = lock
      @cache = cache
      @key_resolver = key_resolver
      @rate = rate
      @wait = wait
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
        end
      end
    end

    private
    attr_reader :app, :lock, :cache, :key_resolver, :rate, :wait, :fallbacks

    def resp(resp_env, status = :fresh, start = Time.now)
      resp_env = Faraday::Env.from(resp_env)
      resp_env[:response_headers].merge!(
        'X-Throttler' => status.to_s,
        'X-ThrottlerTime' => (Time.now - start)
      )

      ::Faraday::Response.new(resp_env)
    end
  end

end
