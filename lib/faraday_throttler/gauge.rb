module FaradayThrottler
  class Gauge
    attr_reader :rate, :wait

    def initialize(rate:, wait:)
      @rate, @wait = rate, wait
    end

    def start(req_id, time = Time.now)

    end

    def update(req_id, state)

    end

    def finish(req_id, state)

    end
  end
end
