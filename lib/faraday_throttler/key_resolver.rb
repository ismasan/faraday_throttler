require 'openssl/digest'

module FaradayThrottler
  class KeyResolver
    def call(request_env)
      hash request_env[:url].to_s
    end

    private
    def hash(str)
      OpenSSL::Digest::MD5.hexdigest(str)
    end
  end
end
