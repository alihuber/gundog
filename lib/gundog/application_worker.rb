require "logger"
require "json"

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
        if defined?(::Rails)
          call_rails_mode(args)
        else
          call_standalone_mode(args)
        end
      rescue Exception => ex
        handle_retry_or_error(args, metadata, delivery_info, channel, ex)
        self.terminate
        return
      end

      channel.acknowledge(delivery_info.delivery_tag, false)
      info("SUCCESS #{self.class.name}")
      self.terminate
    end


    private

    def call_standalone_mode(args)
      parse!(args)
      setup
      call
    end

    def call_rails_mode(args)
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
    end

    def handle_retry_or_error(args, metadata, delivery_info, channel, ex)
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
    end

    def parse!(args)
      if defined?(::Rails)
        @json = ActiveSupport::JSON.decode(args)
      else
        @json = JSON.parse(args)
      end
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
