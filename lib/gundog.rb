require "bunny"
if ENV["TEST"]
  require "celluloid/test"
else
  require "celluloid/current"
end
require "serverengine"

require "gundog/version"
require "gundog/configuration"
require "gundog/publisher"
require "gundog/application_worker"
require "gundog/run_task"


module Gundog
  extend self

  CONFIG = Configuration.new

  def setup(opts={})
    CONFIG.options.merge!(opts)
  end
end
