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
    # Queued requests will wait for up to 3 seconds for current in-flight request
    # to the same path.
    # If in-flight request hasn't finished after that time, return a default placeholder response.
    wait: 3
 )
 c.adapter Faraday.default_adapter
end
```

Make some requests:

```ruby
resp = client.get('/foobar')
resp.body
```

The configuration above will only issue 1 request every 3 seconds to `my.api.com/foobar`. Requests to the same path will wait for up to 3 seconds for current _in-flight_ request to finish. 

If in-flight requests finishes within that period, queued requests will respond with the same data.

If in-flight request doesn't finish within 3 seconds, queued requests will attempt to serve a previous response to the same resource from cache.

If no matching response found in cache, a default fallback response will be used (status 204 No Content).

Tweaking the `rate` and `wait` arguments allows you to control the rate of cached, fresh and fallback reponses.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ismasan/faraday_throttler.

