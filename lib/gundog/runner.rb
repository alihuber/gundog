module Gundog
  class Runner

    def initialize(queue_names, opts = {})
      @opts  = Gundog::CONFIG.options.merge(opts)

      puts "Starting message dispatching for queues: #{queue_names}"
      se = ServerEngine.create(nil, Gundog::Dispatcher, {
        daemonize: false,
        worker_type: "process",
        workers: 1,
        queue_names: queue_names,
        opts: @opts
      })
      se.run
    end
  end
end
