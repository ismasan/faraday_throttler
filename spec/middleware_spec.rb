require 'spec_helper'
require 'faraday_throttler/middleware'
require 'faraday_throttler/key_resolver'

describe FaradayThrottler::Middleware do

  let(:url) { 'http://example.com/test' }

  let(:request_stubs) do
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get(url) { |env| [200, {}, 'response body'] }
    end
  end

  let(:lock) { double('lock', set: true) }
  let(:cache) { double('cache', set: true) }
  let(:key_resolver) { FaradayThrottler::KeyResolver.new }
  let(:fallbacks) { double('fallbacks') }

  let(:conn) do
    Faraday.new do |conn|
      conn.use(described_class, {
        lock: lock,
        cache: cache,
        key_resolver: key_resolver,
        rate: 3,
        wait: 4,
        fallbacks: fallbacks
      })

      conn.adapter :test, request_stubs
    end
  end

  context 'fresh request (no cache, no in-flight request)' do

    let(:key) { key_resolver.call(url: url) }

    it 'requests backend and responds with fresh data' do
      resp = conn.get(url)
      expect(resp.body).to eql 'response body'
    end

    it 'sets lock' do
      expect(lock).to receive(:set).with(key, 3)
      conn.get(url)
    end

    it 'populates cache' do
      expect(cache).to receive(:set) do |k, resp|
        expect(k).to eql key
        expect(resp).to be_a Faraday::Env
        expect(resp[:body]).to eql 'response body'
      end

      conn.get(url)
    end
  end

  context 'previous in-flight request' do

    before do
      conn.get('/test')
    end

    context 'existing cached response' do

    end

    context 'wait for in-flight request' do

    end

    context 'wait timeout, fallback' do

    end
  end

end
