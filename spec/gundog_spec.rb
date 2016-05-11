require "spec_helper"

describe Gundog do

  after do
    # do not disturb other tests by set options
    Gundog.setup.delete(:vhost)
    Gundog.setup.delete(:amqp)
  end

  it "has a version number" do
    expect(Gundog::VERSION).not_to be nil
  end

  it "has a setup method with default settings" do
    expect(Gundog.setup(amqp: "localhost:15672", vhost: "test")).to eq(
      Hash[:heartbeat=>2,
           :exchange=>"gundog",
           :prefetch=>100,
           :retry_timeout=>10,
           :max_retry=>3,
           :workers=>1,
           :exchange_options=> {:type=>:direct,
                                :durable=>true,
                                :auto_delete=>false},
           :queue_options=> {:exclusive=>false,
                             :ack=>true,
                             :durable=>true},
                             :amqp=>"localhost:15672",
                             :vhost=>"test"
      ])
  end
end
