module Gundog
  module Dispatcher

    def initialize
      @stop_flag = ServerEngine::BlockingFlag.new
    end

    def run
      queue_names = config[:queue_names]
      opts        = config[:opts]

      queue_names.each do |name|
        connection  = Bunny.new(opts[:amqp], vhost: opts[:vhost],
                                heartbeat: opts[:heartbeat])
        puts "starting #{connection.inspect} for #{name}"
        connection.start
        channel     = connection.create_channel
        exchange    = channel.exchange(opts[:exchange], opts[:exchange_options])
        queue       = channel.queue(name, opts[:queue_options])
        queue.bind(exchange, :routing_key => name)
        consumer    = build_consumer_class.new(channel, queue)
        queue.subscribe_with(consumer)
        consumer.on_delivery() do |delivery_info, metadata, payload|
          # spawn new worker instance in separate thread with payload
          "#{name}_worker".camelize.constantize.new.async.work(payload)
        end
      end

      until @stop_flag.wait_for_set
      end
    end

    def build_consumer_class
      Class.new(Bunny::Consumer) do
        def cancelled?
          @cancelled
        end

        def handle_cancellation(_)
          @cancelled = true
        end
      end
    end

    def stop
      @stop_flag.set!
    end
  end
end
