require 'spec_helper'
require 'faraday_throttler/serializer'

describe FaradayThrottler::Serializer do
  subject{ described_class.new }

  let(:valid_response) do
    {
      status: 200,
      body: 'Hello',
      response_headers: {
        'Content-Type' => 'text/html'
      }
    }
  end

  let(:invalid_response) do
    {
      body: 'Hello',
      response_headers: {
        'Content-Type' => 'text/html'
      }
    }
  end

  it 'serializes and deseriaizes' do
    raw = subject.serialize(valid_response)
    data = subject.deserialize(raw)
    expect(symbolize(data)).to eql valid_response
  end

  it 'raises if invalid response data' do
    expect{
      subject.serialize(invalid_response)
    }.to raise_error FaradayThrottler::Errors::SerializerError
  end

  def symbolize(data)
    data.each_with_object({}) do |(k, v), m|
      m[k.to_sym] = v
    end
  end
end
