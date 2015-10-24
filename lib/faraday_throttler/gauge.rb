module FaradayThrottler
  class Gauge
    def initialize(rate:, wait:)
      @rate, @wait = rate, wait
    end

    def start(req_id, time = Time.now)

    end

    def update(req_id, state)

    end

    def finish(req_id, state)

    end

    def rate(req_id)
      @rate
    end

    def wait(req_id)
      @wait
    end
  end
end
