module Gundog
  class Configuration

    attr_accessor :options

    CONFIG_DEFAULTS = {
      heartbeat:   2,
      exchange:    "gundog",
      prefetch:    1,
      exchange_options: { type: :direct, durable: true, auto_delete: false },
      queue_options: { exclusive: false, ack: true }
    }.freeze


    def initialize
      @options = Hash.new
      @options.merge!(CONFIG_DEFAULTS)
      @options
    end
  end
end
