require "logger"

module Gundog
  class Publisher
    def initialize(options = {})
      @mutex   = Mutex.new
      @config  = Gundog::CONFIG.options.merge(options)
      @logger  = Logger.new(STDOUT)
    end

    def publish(message, options = {})
      @config.merge!(options)
      @mutex.synchronize do
        ensure_connection! unless connected?
      end
      if connected?
        to_queue = @config.delete(:to_queue)
        @config[:routing_key] ||= to_queue
        @logger.info(
          "Publishing %p to queue %p" % [message, @config[:routing_key]])
        @exchange.publish(message, @config)
        @connection.close
      else
        @logger.warn("Unable to publish %p, aborting..." % message)
      end
    end

    attr_reader :exchange

    private
    def ensure_connection!
      @connection  = @config[:connection]
      @connection  ||= create_connection
      begin
        @connection.start
      rescue Bunny::TCPConnectionFailed => e
        @logger.warn("Error: cannot establish Bunny AMQP connection!")
        @logger.warn(e)
        return
      end
      @channel  = @connection.create_channel
      @exchange =
        @channel.exchange(@config[:exchange], @config[:exchange_options])
    end

    def connected?
      @connection && @connection.connected?
    end

    def create_connection
      Bunny.new(@config[:amqp], vhost: @config[:vhost],
                heartbeat: @config[:heartbeat])
    end
  end
end
