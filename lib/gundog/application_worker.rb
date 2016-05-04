module Gundog
  class ApplicationWorker
    include Celluloid

    def self.disable_transaction!
      define_method :in_transaction? do
        false
      end
    end

    attr_reader :json

    def work(args = '{}', delivery_info, channel)
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
        # false == no requeueing by rabbitmq itself
        channel.reject(delivery_info.delivery_tag, false)
        log_exception(ex)
        queue_name = self.class.to_s.underscore.gsub("worker", "retry")
        Gundog::Publisher.publish(args, to_queue: queue_name)
        return
      end

      channel.acknowledge(delivery_info.delivery_tag, false)
      log_success
      self.terminate
    end


    private

    def log_exception(ex)
      puts "*** EXCEPTION #{self.class.name} ***"
      puts('=' * 80)
      puts ex.message
      puts ex.backtrace
    end

    def log_start(args)
      puts "*** START #{self.class.name} with #{args} ***"
    end

    def log_success
      puts "*** SUCCESS #{self.class.name} ***"
    end

    def parse!(args)
      @json = ActiveSupport::JSON.decode(args)
    end

    def setup
    end

    def call
    end

    def publish_to(queue, data)
      Gundog::Publisher.publish(data.to_json, to_queue: queue)
    end

    def in_transaction?
      true
    end
  end
end
