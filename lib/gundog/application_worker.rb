module Gundog
  class ApplicationWorker
    include Celluloid

    def self.disable_transaction!
      define_method :in_transaction? do
        false
      end
    end

    attr_reader :json

    def work(args = "{}", metadata, delivery_info, channel)
      log_start(args)

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
        log_exception(ex)
        queue_name = delivery_info.routing_key + "_retry"
        if metadata[:headers]
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
      log_success
      self.terminate
    end


    private

    def log_exception(ex)
      puts "#{Time.zone.now.to_s}  *** EXCEPTION #{self.class.name} ***"
      puts('=' * 80)
      puts ex.message
      puts ex.backtrace
    end

    def log_start(args)
      puts "#{Time.zone.now.to_s}  *** START #{self.class.name} with #{args} ***"
    end

    def log_success
      puts "#{Time.zone.now.to_s}  *** SUCCESS #{self.class.name} ***"
    end

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
