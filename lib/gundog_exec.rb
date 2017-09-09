require "bunny"
require "optparse"

if ENV["TEST"]
  require "celluloid/test"
else
  require "celluloid/current"
end
require "serverengine"
require "net/ping"
require "logger"

require "gundog/configuration"
require "gundog/publisher"
require "gundog/application_worker"
require "gundog/dispatcher"
require "gundog/retry_worker"
require "gundog/runner"

module Gundog
  extend self

  CONFIG = Configuration.new

  def setup(opts={})
    CONFIG.options.merge!(opts)
  end
end

@options = {}
optparse = OptionParser.new do |opts|
  opts.banner = "Usage: gundog --url [amqp_url] --vhost [vhost]"\
    " --worker [worker_class_1,worker_class_n]"

  @options[:workers] = []
  opts.on("-w", "--worker worker_1,worker_n", Array, "Supply a comma-separated"\
            " list of snake_cased worker class files.") do |workers|
    @options[:workers] = workers
  end

  @options[:url] = "amqp://guest:guest@localhost:5672"
  opts.on("-u", "--url URL", "The AMQP connection URL in the form of"\
            " amqp://<username>:<password>@<ip>:<port>") do |url|
    @options[:url] = url
  end

  @options[:vhost] = "/"
  opts.on("-v", "--vhost VHOST", "Name of the vhost, default: /") do |vhost|
    @options[:vhost] = vhost
  end

  opts.on("-h", "--help", "Print this help screen") do
    puts opts
    exit
  end
end

optparse.parse!

workers = []
if @options[:workers].any?
  @options[:workers].each do |worker|
    require "./#{worker}"
    if worker.include?("/")
      worker = worker.slice(worker.rindex("/") + 1, worker.length)
    end
    if worker.include?(".rb")
      worker = worker.slice(0, worker.rindex("."))
    end
    workers << worker
  end
end

Gundog.setup[:amqp]  = @options[:url] unless @options[:url].empty?
Gundog.setup[:vhost] = @options[:vhost] unless @options[:vhost].empty?

def connection_up?(uri)
  check = Net::Ping::External.new(uri.host)
  check.ping?
end

if workers.any? && connection_up?(URI(Gundog.setup[:amqp]))
  Gundog::Runner.new(workers)
else
  Logger.new(STDOUT).warn(
    "No worker names given or target server not reachable, aborting...")
end
