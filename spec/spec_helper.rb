require "simplecov"
SimpleCov.start

ENV["TEST"] ||= "test"

Dir["#{Dir.pwd}/spec/contexts/**/*.rb"].each { |f| require f }
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require "json"
require "active_support"
require "active_support/inflector"
require "active_support/time"
require "active_record"
require "ostruct"
require "celluloid/test"
require "gundog"



RSpec.configure do |config|
  config.before :each do
    Celluloid.boot
  end

  config.after :each do
    Celluloid.shutdown
  end
end

ActiveRecord::Base.establish_connection :adapter => :nulldb
