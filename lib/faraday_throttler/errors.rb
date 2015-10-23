module FaradayThrottler
  module Errors
    class ThrottlerError < StandardError; end
    class SerializerError < ThrottlerError; end
  end
end
