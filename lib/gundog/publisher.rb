module Gundog
  class Publisher

    def self.publish(message, opts = {})
      @opts  = Gundog::CONFIG.options.merge(opts)
      ensure_connection!
      to_queue = @opts.delete(:to_queue)
      @opts[:routing_key] ||= to_queue
      puts "#{Time.zone.now.to_s}  "\
        "publishing #{message} to queue #{@opts[:routing_key]}"
      @exchange.publish(message, @opts)
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

  end
end
