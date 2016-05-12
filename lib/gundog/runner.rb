module Gundog
  class Runner

    def initialize(worker_names, options = {})
      @options  = Gundog::CONFIG.options.merge(options)

      puts "Starting message dispatching for workers: #{worker_names}"
      se = ServerEngine.create(nil, Gundog::Dispatcher, {
        daemonize: @options[:daemonize],
        log: @options[:log],
        pid_path: @options[:pid_path],
        worker_type: "process",
        workers: @options[:workers] || 1,
        worker_names: worker_names,
        options: @options
      })
      se.run
    end
  end
end
