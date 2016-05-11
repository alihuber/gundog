module Gundog
  class Publisher
    def initialize(options = {})
      @mutex          = Mutex.new
      @configuration  = Gundog::CONFIG.options.merge(options)
    end

    def publish(message, options = {})
      @configuration.merge!(options)
      @mutex.synchronize do
        ensure_connection! unless connected?
      end
      to_queue = @configuration.delete(:to_queue)
      @configuration[:routing_key] ||= to_queue
      puts "#{Time.zone.now.to_s}  "\
        "publishing #{message} to queue #{@configuration[:routing_key]}"
      @exchange.publish(message, @configuration)
      @connection.close
    end

    attr_reader :exchange

    private
    def ensure_connection!
      @connection  = @configuration[:connection]
      @connection  ||= create_connection
      @connection.start
      @channel     = @connection.create_channel
      @exchange    = @channel.exchange(@configuration[:exchange],
                                       @configuration[:exchange_options])
    end

    def connected?
      @connection && @connection.connected?
    end

    def create_connection
      Bunny.new(@configuration[:amqp], vhost: @configuration[:vhost],
                heartbeat: @configuration[:heartbeat])
    end
  end
end
