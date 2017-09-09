require "gundog"
require "gundog/dispatcher"
require "gundog/retry_worker"
require "gundog/runner"
require "net/ping"
require "logger"

task :environment

namespace :gundog do
  desc "Start worker process"
  task :run do
    Rake::Task["environment"].invoke

    if defined?(::Rails)
      ::Rails.application.eager_load!
      workers = Rails.application.config_for(:workers)["workers"]
    end

    if workers.any? && connection_up?(URI(Gundog.setup[:amqp]))
      Gundog::Runner.new(workers)
    else
      Logger.new(STDOUT).warn(
        "No worker names given or target server not reachable, aborting...")
    end
  end

  def connection_up?(uri)
    check = Net::Ping::External.new(uri.host)
    check.ping?
  end
end
