require 'spec_helper'
require 'faraday_throttler/redis_lock'

describe FaradayThrottler::RedisLock do
  let(:redis) { double('redis') }

  subject{ described_class.new(redis) }
  let(:key1) { 'aaa' }

  it 'delegates to redis SET with ex and nx options' do
    lock_key = [described_class::NAMESPACE, key1].join

    allow(redis).to receive(:set).with(lock_key, '1', ex: 10, nx: true).and_return true
    expect(subject.set(key1, 10)).to be true

    allow(redis).to receive(:set).with(lock_key, '1', ex: 11, nx: true).and_return false
    expect(subject.set(key1, 11)).to be false
  end
end
