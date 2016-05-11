module Gundog
  class Runner

    def initialize(queue_names, options = {})
      @options  = Gundog::CONFIG.options.merge(options)

      puts "Starting message dispatching for queues: #{queue_names}"
      se = ServerEngine.create(nil, Gundog::Dispatcher, {
        daemonize: false,
        worker_type: "process",
        workers: @options[:workers] || 1,
        queue_names: queue_names,
        options: @options
      })
      se.run
    end
  end
end
