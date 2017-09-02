require "logger"

module Gundog
  module Dispatcher

    def initialize
      @stop_flag = ServerEngine::BlockingFlag.new
      # config == implicit serverengine options with merged in gundog options
      @config    = config
      @logger    = Logger.new(STDOUT)
    end

    def run
      worker_names = @config[:worker_names]
      ack          = @config[:queue_options][:ack]

      worker_names.each do |worker_name|
        queue_name       = worker_name + "_queue"
        retry_queue_name = queue_name + "_retry"
        error_queue_name = queue_name + "_error"

        connection       = Bunny.new(@config[:amqp], vhost: @config[:vhost],
                                     heartbeat: @config[:heartbeat])
        @logger.info("Starting %p for %p" % [connection, worker_name])

        begin
          connection.start
          channel            = connection.create_channel
          channel.prefetch(@config[:prefetch])
          exchange           =
            channel.exchange(@config[:exchange], @config[:exchange_options])


          worker_queue       = channel.queue(queue_name, @config[:queue_options])
          worker_queue.bind(exchange, :routing_key => queue_name)
          # build long lived consumer to listen on deliveries
          # channel, queue, comsumer_tag, no_ack, exclusive, opts
          work_consumer      = build_consumer_class
            .new(channel, worker_queue, "#{queue_name}-consumer", false)
          # subscribe ephemeral consumer to work off piled up messages
          off_work_consumer  = worker_queue
            .subscribe(block: false, manual_ack: ack) do |info, meta, message|
            work_actor       = worker_name.camelize.constantize.new
            work_actor.async.work(message, meta, info, channel)
          end
          worker_queue.subscribe_with(work_consumer)
          work_consumer.on_delivery() do |delivery_info, metadata, payload|
            work_actor       = worker_name.camelize.constantize.new
            work_actor.async.work(payload, metadata, delivery_info, channel)
          end


          retry_queue        =
            channel.queue(retry_queue_name, @config[:queue_options])
          retry_queue.bind(exchange, :routing_key => retry_queue_name)
          retry_consumer     =
            build_consumer_class.new(channel, retry_queue,
                                     "#{retry_queue_name}-consumer", false)
          off_retry_consumer = retry_queue
            .subscribe(block: false, manual_ack: ack) do |info, meta, message|
            retry_actor      = worker_name.camelize.constantize.new
            retry_actor.async.work(message, meta, info, channel)
          end
          retry_queue.subscribe_with(retry_consumer)
          retry_consumer.on_delivery() do |delivery_info, metadata, payload|
            retry_actor      =
              Gundog::RetryWorker.new(@config[:retry_timeout],
                                      @config[:max_retry])
            retry_actor.async.call(payload, metadata, delivery_info, channel)
          end

          error_queue        =
            channel.queue(error_queue_name, @config[:queue_options])
          error_queue.bind(exchange, :routing_key => error_queue_name)

          off_work_consumer.cancel
          off_retry_consumer.cancel
        rescue Exception => e
          @logger.warn("BUNNY EXCEPTION: #{e.message}")
          @logger.warn(
            "Please make sure queues are empty and delete them manually if necessary."
          )
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
