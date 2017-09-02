require "gundog/dispatcher"

class DispatcherClass
  include Gundog::Dispatcher
  # mock implicit serverengine "config" settings hash
  def config
    Hash[daemonize: false,
     log: STDOUT,
     pid_path: "gundog.pid",
     worker_type: "process",
     workers:  1]
  end
end
