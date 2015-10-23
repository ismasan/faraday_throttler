require 'spec_helper'
require 'faraday_throttler/mem_lock'

describe FaradayThrottler::MemLock do
  subject{ described_class.new }
  let(:key1) { 'aaa' }

  describe '#set(key, ttl)' do
    it 'sets lock for key for given TTL and returns true' do
      expect(subject.set(key1, 10)).to be true
      expect(subject.set(key1, 10)).to be false

      now = Time.now
      expect(Time).to receive(:now).and_return now + 11
      expect(subject.set(key1, 10)).to be true
    end
  end
end
