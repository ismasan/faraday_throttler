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

      key = key_resolver.call(request_env)

      if lock.set(key, rate)
        app.call(request_env).on_complete do |response_env|
          cache.set key, response_env
        end
      end
    end

    private
    attr_reader :app, :lock, :cache, :key_resolver, :rate, :wait, :fallbacks
  end

end
