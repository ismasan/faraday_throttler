require 'spec_helper'
require 'faraday_throttler/gauge'

describe FaradayThrottler::Gauge do

  subject{ described_class.new(rate: 1, wait: 2) }

  it 'exposes #rate and #wait' do
    expect(subject.rate('foo')).to eql 1
    expect(subject.wait('foo')).to eql 2
  end

end
