module FaradayThrottler
  module Retryable
    private

    def with_retry(wait, &block)
      r = block.call
      return r if r || wait == 0
      
      value = nil
      ticks = 0
      while ticks <= wait do
        Kernel.sleep 1 
        ticks += 1
        value = block.call
      end

      value
    end
  end
end

