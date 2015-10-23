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
  let(:cache) { double('cache', get: true, set: true) }
  let(:key_resolver) { FaradayThrottler::KeyResolver.new }
  let(:fallbacks) { double('fallbacks', call: true) }

  let(:key) { key_resolver.call(url: url) }

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

  context 'dependencies' do
    let(:app) { double('app') }

    describe 'defaults' do
      it 'works' do
        expect{
          described_class.new(app)
        }.not_to raise_error
      end
    end

    describe 'invalid lock' do
      it 'complains' do
        expect{
          described_class.new(app, lock: double('lock'))
        }.to raise_error(ArgumentError)
      end
    end

    describe 'invalid cache' do
      it 'complains' do
        expect{
          described_class.new(app, cache: double('cache'))
        }.to raise_error(ArgumentError)
      end
    end

    describe 'invalid key resolver' do
      it 'complains' do
        expect{
          described_class.new(app, key_resolver: double('key resolver'))
        }.to raise_error(ArgumentError)
      end
    end

    describe 'invalid fallbacks' do
      it 'complains' do
        expect{
          described_class.new(app, fallbacks: double('fallbacks'))
        }.to raise_error(ArgumentError)
      end
    end
  end

  context 'fresh request (no cache, no in-flight request)' do

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
      allow(lock).to receive(:set).with(key, 3).and_return false
    end

    context 'existing cached response' do
      let(:cached_response) do
        {
          method: :get,
          body: 'previous response body',
          status: 200,
          response_headers: {'Content-type' => 'text/html'}
        }
      end

      before do
        allow(cache).to receive(:get).with(key, 4).and_return cached_response
      end

      it 'returns cached response inmediatly' do
        resp = conn.get(url)
        expect(resp.body).to eql 'previous response body'
        expect(resp.headers['X-Throttler']).to eql 'cached'
      end
    end

    context 'no previous cached response' do
      let(:fallback_response) do
        {
          method: :get,
          body: 'No content yet',
          status: 200,
          response_headers: {'Content-type' => 'text/html'}
        }
      end

      before do
        allow(cache).to receive(:get).with(key, 4).and_return nil
      end

      it 'resolves and returns fallback response' do
        expect(fallbacks).to receive(:call) do |req|
          expect(req[:url].to_s).to eql url
        end.and_return fallback_response

        resp = conn.get(url)
        expect(resp.body).to eql 'No content yet'
        expect(resp.headers['X-Throttler']).to eql 'fallback'
      end
    end

    context 'wait timeout, fallback' do
      
    end
  end

end
