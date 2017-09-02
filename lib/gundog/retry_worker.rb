require "logger"

module Gundog
  class RetryWorker
    include Celluloid
    include Celluloid::Internals::Logger

    def initialize(timeout, max_retry)
      @timeout   = timeout
      @max_retry = max_retry
    end

    def call(args, metadata, delivery_info, channel)
      after(@timeout) do
        check_max_times(args, metadata, delivery_info, channel)
      end
    end

    private
    def check_max_times(args, metadata, delivery_info, channel)
      queue_name = delivery_info[:routing_key].gsub("_retry", "")
      if metadata[:headers]["retry_count"] > @max_retry
        info("Moving %p into %p error queue after %p retries" %
             [args, queue_name, @max_retry])
        Gundog::Publisher.new.publish(args, to_queue: "#{queue_name}_error")
        # requeue automatically = false
        channel.reject(delivery_info.delivery_tag, false)
        self.terminate
      else
        count = metadata[:headers]["retry_count"]
        info("Publishing %p to %p after %p seconds for the %p. time" %
             [args, queue_name, @timeout, count])
        Gundog::Publisher.new.publish(args, to_queue: queue_name,
                                      headers: {retry_count: count + 1})
        channel.acknowledge(delivery_info.delivery_tag, false)
        self.terminate
      end
    end
  end
end
