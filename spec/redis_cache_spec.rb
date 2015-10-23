require 'spec_helper'
require 'faraday_throttler/redis_cache'

describe FaradayThrottler::RedisCache, type: :cache do
  let(:redis) { double('redis') }
  let(:serializer) { FaradayThrottler::Serializer.new }

  subject { described_class.new(redis: redis, ttl: 20, serializer: serializer) }

  let(:json) { %({"status": 200, "response_headers": {"Content-Type": "text/html"}, "body": "hi"}) }
  let(:key) { [described_class::NAMESPACE, 'aaa'].join }

  context 'when cache is populated' do

    before do
      allow(redis)
        .to receive(:get)
        .with(key)
        .and_return(json)
    end

    it 'gets data' do
      resp = subject.get('aaa')
      assert_response resp
    end

    it 'returns data regardless of wait time' do
      expect(Kernel).not_to receive(:sleep)
      resp = subject.get('aaa', 10)
      assert_response resp
    end
  end

  describe '#set' do
    it 'sets data in redis' do
      r = double('response')
      expect(serializer).to receive(:serialize).with(r).and_return 'data'
      expect(redis).to receive(:set).with(key, 'data', ex: 20).and_return true

      expect(subject.set('aaa', r)).to eql true

    end
  end

  def assert_response(resp)
    expect(resp['status']).to eql 200
    expect(resp['body']).to eql 'hi'
    expect(resp['response_headers']['Content-Type']).to eql 'text/html'
  end
end
