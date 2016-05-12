require "gundog"
require "gundog/dispatcher"
require "gundog/retry_worker"
require "gundog/runner"

task :environment

namespace :gundog do
  desc "Start worker process"
  task :run do
    Rake::Task["environment"].invoke

    ::Rails.application.eager_load!

    workers = Rails.application.config_for(:workers)["workers"]
    if workers.any?
      Gundog::Runner.new(workers)
    else
      puts "No worker names given, aborting..."
    end
  end
end
