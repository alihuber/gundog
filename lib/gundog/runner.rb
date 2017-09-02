require "logger"

module Gundog
  class Runner

    def initialize(worker_names, options = {})
      options  = Gundog::CONFIG.options.merge(options)
      serverengine_config = Hash[daemonize: options.delete(:daemonize),
        log: options.delete(:log),
        pid_path: options.delete(:pid_path),
        worker_type: "process",
        workers: options.delete(:workers) || 1,
        worker_names: worker_names]
      setup =  serverengine_config.merge(options)

      Logger.new(STDOUT).info(
        "Starting message dispatching for workers: #{worker_names}")
      se = ServerEngine.create(nil, Gundog::Dispatcher, setup)
      se.run
    end
  end
end
