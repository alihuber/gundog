module Gundog
  class Publisher

    def self.publish(msg, opts = {})
      @opts  = Gundog::CONFIG.options.merge(opts)
      ensure_connection!
      to_queue = @opts.delete(:to_queue)
      @opts[:routing_key] ||= to_queue
      puts "publishing #{msg} to queue #{@opts[:routing_key]}"
      @exchange.publish(msg, @opts)
      @connection.close
    end


    private
    def self.ensure_connection!
      @connection ||= Bunny.new(@opts[:amqp], vhost: @opts[:vhost],
                                heartbeat: @opts[:heartbeat])
      @connection.start
      @channel    = @connection.create_channel
      @exchange   = @channel.exchange(@opts[:exchange],
                                      @opts[:exchange_options])
    end
    private_class_method :ensure_connection!

    def self.connected?
      @connection && @connection.connected?
    end
    private_class_method :connected?

  end
end
