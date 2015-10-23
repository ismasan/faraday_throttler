module FaradayThrottler
  class Fallbacks
    DEFAULT_CONTENT_TYPE = 'application/json'.freeze

    def call(req)
      {
        url: req[:url],
        status: 204,
        body: '',
        response_headers: {
          'Content-Type' => req.fetch(:request_headers, {}).fetch('Content-Type', DEFAULT_CONTENT_TYPE)
        }
      }
    end
  end
end
