require "spec_helper"
require_relative "dispatcher_class"

describe Gundog::Dispatcher do
  include_context :bunny_connection

  # Dispatcher is a module started by serverengine, has to be included

  let(:config)        { Hash[:queue_names=>["queue_1", "queue_2"],
                             :options=>
                               {:heartbeat=>2,
                               :exchange=>"gundog",
                               :prefetch=>100,
                               :retry_timeout=>10,
                               :max_retry=>3,
                               :exchange_options=>
                               {:type=>:direct, :durable=>true,
                                :auto_delete=>false},
                               :queue_options=>
                               {:exclusive=>false, :ack=>true, :durable=>true}}]
  }
  let(:dispatcher)    { DispatcherClass.new }
  let(:queue_1)       { double("Queue1") }
  let(:queue_2)       { double("Queue2") }
  let(:retry_queue_1) { double("RetryQueue1") }
  let(:retry_queue_2) { double("RetryQueue2") }
  let(:error_queue_1) { double("ErrorQueue1") }
  let(:error_queue_2) { double("ErrorQueue2") }
  let(:flag)          { double("StopFlag") }
  let(:off_consumer)  { OpenStruct.new(cancel: true) }

  subject { dispatcher.run }

  before do
    allow(dispatcher).to receive(:config).and_return(config)
    allow(dispatcher).to receive(:stop_flag).and_return false
    allow_any_instance_of(ServerEngine::BlockingFlag)
      .to receive(:wait_for_set).and_return ServerEngine::BlockingFlag.new.set!

    allow(channel).to receive(:queue)
      .with("queue_1", {:exclusive=>false, :ack=>true, :durable=>true})
      .and_return(queue_1)
    allow(channel).to receive(:queue)
      .with("queue_2", {:exclusive=>false, :ack=>true, :durable=>true})
      .and_return(queue_2)
    allow(channel).to receive(:queue)
      .with("queue_1_retry", {:exclusive=>false, :ack=>true, :durable=>true})
      .and_return(retry_queue_1)
    allow(channel).to receive(:queue)
      .with("queue_2_retry", {:exclusive=>false, :ack=>true, :durable=>true})
      .and_return(retry_queue_2)
    allow(channel).to receive(:queue)
      .with("queue_1_error", {:exclusive=>false, :ack=>true, :durable=>true})
      .and_return(error_queue_1)
    allow(channel).to receive(:queue)
      .with("queue_2_error", {:exclusive=>false, :ack=>true, :durable=>true})
      .and_return(error_queue_2)

    allow(queue_1).to receive(:bind).with(exchange, {:routing_key=>"queue_1"})
    allow(queue_2).to receive(:bind).with(exchange, {:routing_key=>"queue_2"})
    allow(retry_queue_1)
      .to receive(:bind).with(exchange, {:routing_key=>"queue_1_retry"})
    allow(retry_queue_2)
      .to receive(:bind).with(exchange, {:routing_key=>"queue_2_retry"})
    allow(error_queue_1)
      .to receive(:bind).with(exchange, {:routing_key=>"queue_1_error"})
    allow(error_queue_2)
      .to receive(:bind).with(exchange, {:routing_key=>"queue_2_error"})

    allow(queue_1).to receive(:subscribe_with)
    allow(queue_2).to receive(:subscribe_with)
    allow(queue_1).to receive(:subscribe).and_return(off_consumer)
    allow(queue_2).to receive(:subscribe).and_return(off_consumer)

    allow(retry_queue_1).to receive(:subscribe_with)
    allow(retry_queue_2).to receive(:subscribe_with)
    allow(retry_queue_1).to receive(:subscribe).and_return(off_consumer)
    allow(retry_queue_2).to receive(:subscribe).and_return(off_consumer)
  end


  it "sets up rabbitmq queues from queue name array" do
    subject
    expect(queue_1)
      .to have_received(:bind).with(exchange, {:routing_key=>"queue_1"})
    expect(queue_2)
      .to have_received(:bind).with(exchange, {:routing_key=>"queue_2"})
    expect(retry_queue_1)
      .to have_received(:bind).with(exchange, {:routing_key=>"queue_1_retry"})
    expect(retry_queue_2)
      .to have_received(:bind).with(exchange, {:routing_key=>"queue_2_retry"})
    expect(error_queue_1)
      .to have_received(:bind).with(exchange, {:routing_key=>"queue_1_error"})
    expect(error_queue_2)
      .to have_received(:bind).with(exchange, {:routing_key=>"queue_2_error"})

    expect(queue_1).to have_received(:subscribe_with)
    expect(queue_2).to have_received(:subscribe_with)
    expect(retry_queue_1).to have_received(:subscribe_with)
    expect(retry_queue_2).to have_received(:subscribe_with)
  end

  it "handles Bunny connection errors" do
    allow(queue_1).to receive(:bind).with(exchange, {:routing_key=>"queue_1"})
      .and_raise(Bunny::PreconditionFailed.new("error", channel, true))

    subject

    expect(queue_1).not_to have_received(:subscribe_with)
  end

  # actual worker spawning is done in seperate process, not tested here
end
