require "gundog"
require "gundog/dispatcher"
require "gundog/retry_worker"
require "gundog/runner"
require "net/ping"

task :environment

namespace :gundog do
  desc "Start worker process"
  task :run do
    Rake::Task["environment"].invoke

    if defined?(::Rails)
      ::Rails.application.eager_load!
      workers = Rails.application.config_for(:workers)["workers"]
    else
      # TODO load setup for workers from elsewhere
    end

    if workers.any? && connection_up?(URI(Gundog.setup[:amqp]))
      Gundog::Runner.new(workers)
    else
      puts "No worker names given or target server not reachable, aborting..."
    end
  end

  def connection_up?(uri)
    check = Net::Ping::External.new(uri.host)
    check.ping?
  end
end
