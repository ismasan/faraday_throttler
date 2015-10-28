[ ![Codeship Status for ismasan/faraday_throttler](https://codeship.com/projects/40d401a0-5c01-0133-561a-22b0ee77d2e6/status?branch=master)](https://codeship.com/projects/110895)

# FaradayThrottler

Configurable Faraday middleware for Ruby HTTP clients that:

* limits request rate to backend services.
* does its best to return cached or placeholder responses to clients while backend service is unavailable or slow.
* optionally uses Redis to rate-limit outgoing requests across processes and servers.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'faraday_throttler'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install faraday_throttler

## Usage

### Defaults

The defaul configuration use an in-memory lock and in-memory cache. Not suitable for multi-server deployments.

```ruby
require 'faraday'
require 'faraday_throttler'

client = Faraday.new(:url => 'https://my.api.com') do |c|
 c.use(
    :throttler,
    # Allow up to 1 request every 3 seconds, per path, to backend
    rate: 3,
    # Queued requests will wait for up to 2 seconds for current in-flight request
    # to the same path.
    # If in-flight request hasn't finished after that time, return a default placeholder response.
    wait: 2
 )
 c.adapter Faraday.default_adapter
end
```

Make some requests:

```ruby
resp = client.get('/foobar')
resp.body
```

The configuration above will only issue 1 request every 3 seconds to `my.api.com/foobar`. Requests to the same path will wait for up to 2 seconds for current _in-flight_ request to finish. 

If an in-flight request finishes within that period, queued requests will respond with the same data.

If the in-flight request doesn't finish within 2 seconds, queued requests will attempt to serve a previous response from the same resource from cache.

If no matching response found in cache, a default fallback response will be used (status 204 No Content). Fallback responses can be cofigured.

Tweaking the `rate` and `wait` arguments allows you to control the rate of cached, fresh and fallback reponses.

### Distributed Redis lock and cache

The defaults use in-memory lock and cache store implementations. To make the most efficient use of this gem across processes and servers, you can use [Redis](http://redis.io/) as a distributed lock and cache store.

```ruby
require 'redis'
require 'faraday_throttler/redis_lock'
require 'faraday_throttler/redis_cache'

redis = Redis.new('my-redis-server.com:1234')

redis_lock = FaradayThrottler::RedisLock.new(redis)

# Cache entries will be available for 1 hour
redis_cache = FaradayThrottler::RedisCache.new(redis: redis, ttl: 3600)

client = Faraday.new(:url => 'https://my.api.com') do |c|
 c.use(
    :throttler,
    rate: 3,
    wait: 2,
    # Use Redis-backed lock
    lock: redis_lock,
    # Use Redis-backed cache with set expiration
    cache: redis_cache
 )
 c.adapter Faraday.default_adapter
end
```

## Advanced usage

Most internal behaviours are split into delegate objects that you can pass as middleware arguments to override the defaults. See the details [in the code](https://github.com/ismasan/faraday_throttler/blob/master/lib/faraday_throttler/middleware.rb#L16).

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ismasan/faraday_throttler.

To contribute with code:

1. Fork it ( http://github.com/ismasan/faraday_throttler/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
