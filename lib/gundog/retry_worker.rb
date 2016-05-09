module Gundog
  class RetryWorker
    include Celluloid

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
        puts "moving #{args} into #{queue_name}_error "\
          "queue after #{@max_retry} times"
        Gundog::Publisher
          .publish(args, to_queue: "#{queue_name}_error")
        # requeue manually = false
        channel.reject(delivery_info.delivery_tag, false)
        self.terminate
      else
        count = metadata[:headers]["retry_count"]
        puts "publishing #{args} into #{queue_name} "\
          "after #{@timeout} seconds for the #{count}. time"
        Gundog::Publisher.publish(args, to_queue: queue_name,
                                        headers: {retry_count: count + 1})
        channel.acknowledge(delivery_info.delivery_tag, false)
        self.terminate
      end
    end
  end
end
