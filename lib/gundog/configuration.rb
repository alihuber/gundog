module Gundog
  class Configuration

    attr_accessor :options

    CONFIG_DEFAULTS = {
      heartbeat:   2,
      exchange:    "gundog",
      prefetch:    100,
      # seconds
      retry_timeout: 10,
      max_retry: 3,
      workers: 1,
      exchange_options: { type: :direct, durable: true, auto_delete: false },
      queue_options: { exclusive: false, ack: true, durable: true }
    }.freeze


    def initialize
      @options = Hash.new
      @options.merge!(CONFIG_DEFAULTS)
      @options
    end
  end
end
