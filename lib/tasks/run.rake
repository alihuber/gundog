require "gundog"
require "gundog/dispatcher"
require "gundog/runner"

task :environment

namespace :gundog do
  desc "Start worker process"
  task :run do
    Rake::Task["environment"].invoke

    ::Rails.application.eager_load!

    queues = Rails.application.config_for(:queues)["queues"]
    if queues.any?
      Gundog::Runner.new(queues)
    else
      puts "No queue names given, aborting..."
    end
  end
end
