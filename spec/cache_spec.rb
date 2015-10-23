require 'spec_helper'
require 'faraday_throttler/cache'

describe FaradayThrottler::Cache do
  subject{ described_class.new }

  context 'when cache is populated' do
    before { subject.set('aaa', 'bbb') }

    it 'gets data' do
      expect(subject.get('aaa')).to eql 'bbb'
    end
  end

  context 'when cache is empty' do
    it 'returns nil' do
      expect(subject.get('aaa')).to be nil
    end
  end

  context 'with wait time' do
    it 'polls store for a time' do
      s1 = Thread.new do
        subject.get('aaa', 0.6)
      end
      s2 = Thread.new do
        sleep 0.2
        subject.set('aaa', 'ccc')
      end

      s1.join
      s2.join

      expect(s1.value).to eql 'ccc'
    end
  end
end
