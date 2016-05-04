module Gundog
  class RetryWorker
    include Celluloid

    def initialize(timeout)
      @timeout = timeout
    end

    def call(args, delivery_info, channel)
      after(@timeout) do
        puts "publishing #{args} into #{delivery_info[:routing_key]} "\
          "after #{@timeout} seconds"
        Gundog::Publisher.publish(args, to_queue: delivery_info[:routing_key])
        channel.acknowledge(delivery_info.delivery_tag, false)
        self.terminate
      end
    end
  end
end
