module Gundog
  module Dispatcher

    def initialize
      @stop_flag = ServerEngine::BlockingFlag.new
    end

    def run
      queue_names = config[:queue_names]
      opts        = config[:opts]

      queue_names.each do |name|
        retry_queue_name = name + "_retry"
        error_queue_name = name + "_error"

        connection       = Bunny.new(opts[:amqp], vhost: opts[:vhost],
                                     heartbeat: opts[:heartbeat])
        puts "#{Time.zone.now.to_s}  starting #{connection.inspect} for #{name}"
        begin
          connection.start
          channel            = connection.create_channel
          exchange           =
            channel.exchange(opts[:exchange], opts[:exchange_options])

          worker_queue       = channel.queue(name, opts[:queue_options])
          worker_queue.bind(exchange, :routing_key => name)
          # channel, queue, comsumer_tag, no_ack, exclusive, opts
          work_consumer      =
            build_consumer_class.new(channel, worker_queue, nil, false)
          worker_queue.subscribe_with(work_consumer)

          retry_queue        =
            channel.queue(retry_queue_name, opts[:queue_options])
          retry_queue.bind(exchange, :routing_key => retry_queue_name)
          retry_consumer     =
            build_consumer_class.new(channel, retry_queue, nil, false)
          retry_queue.subscribe_with(retry_consumer)

          error_queue        =
            channel.queue(error_queue_name, opts[:queue_options])
          error_queue.bind(exchange, :routing_key => error_queue_name)

          work_consumer.on_delivery() do |delivery_info, metadata, payload|
            work_actor       = "#{name}_worker".camelize.constantize.new
            work_actor.async.work(payload, metadata, delivery_info, channel)
          end

          retry_consumer.on_delivery() do |delivery_info, metadata, payload|
            retry_actor      =
              Gundog::RetryWorker.new(opts[:retry_timeout], opts[:max_retry])
            retry_actor.async.call(payload, metadata, delivery_info, channel)
          end
        rescue Bunny::PreconditionFailed, Bunny::ChannelAlreadyClosed => e
          puts "BUNNY EXCEPTION: #{e.message}"
          puts "Please make sure queues are "\
               "empty and delete them manually if necessary."
          parent_process_pid = %x{ps -p #{Process.pid} -o ppid=}.strip
          Process.kill "TERM", parent_process_pid.to_i
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
