require 'spec_helper'
require 'uri'
require 'faraday_throttler/key_resolver'

describe FaradayThrottler::KeyResolver do
  subject{ described_class.new }

  let(:url) { URI.parse('http://www.server.com/foo') }
  let(:req) do
    {
      url: url
    }
  end

  describe '#call' do
    it 'hashes the request URL' do
      key = subject.call(req)
      hash = OpenSSL::Digest::MD5.hexdigest(url.to_s)
      expect(key).to eql hash
    end
  end
end
