require "logger"

module Gundog
  class ApplicationWorker
    include Celluloid
    include Celluloid::Internals::Logger

    def self.disable_transaction!
      define_method :in_transaction? do
        false
      end
    end

    attr_reader :json

    def work(args = "{}", metadata, delivery_info, channel)
      info("START #{self.class.name} with %p" % args)

      begin
        parse!(args)
        ActiveRecord::Base.connection_pool.with_connection do
          setup

          if in_transaction?
            ActiveRecord::Base.transaction do
              call
            end
          else
            call
          end
        end
      rescue Exception => ex
        # 'Should all unacknowledged messages up to this be acknowledged as well?'
        # = false
        channel.acknowledge(delivery_info.delivery_tag, false)
        warn("EXCEPTION #{self.class.name} \n#{ex.message} \n#{ex.backtrace}")
        queue_name = delivery_info.routing_key + "_retry"
        # messages sent by RabbitMQ-UI will add metadata =
        # {:headers=>{}, :delivery_mode=>1}
        if metadata[:headers]&.any?
          Gundog::Publisher.new
            .publish(args, to_queue: queue_name, headers: metadata[:headers])
        else
          Gundog::Publisher.new.publish(args, to_queue: queue_name,
                                        headers: {retry_count: 1})
        end
        self.terminate
        return
      end

      channel.acknowledge(delivery_info.delivery_tag, false)
      info("SUCCESS #{self.class.name}")
      self.terminate
    end


    private

    def parse!(args)
      @json = ActiveSupport::JSON.decode(args)
    end

    def setup
    end

    def call
    end

    def publish_to(queue, data)
      Gundog::Publisher.new.publish(data.to_json, to_queue: queue)
    end

    def in_transaction?
      true
    end
  end
end
