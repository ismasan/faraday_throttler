require 'json'
require 'faraday_throttler/errors'

module FaradayThrottler
  class Serializer
    def serialize(resp)
      validate_response! resp

      hash = {
        status: resp[:status],
        body: resp[:body],
        response_headers: resp[:response_headers]
      }

      JSON.dump hash
    end

    def deserialize(json)
      JSON.parse(json.to_s) 
    rescue JSON::ParserError => e
      raise Errors::SerializerError, e.message
    end

    private
    def validate_response!(resp)
      unless resp.has_key?(:status) && resp.has_key?(:body) && resp.has_key?(:response_headers)
        raise Errors::SerializerError, "response is not valid. Fields: #{resp.keys}"
      end
    end
  end
end
