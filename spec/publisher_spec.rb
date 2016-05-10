require "spec_helper"

describe Gundog::Publisher do
  # include_context :bunny_connection

  let(:publisher) { described_class }
  let!(:bunny_mock) { double(::Bunny.new) }
  let!(:channel)    { double("Channel") }
  let!(:exchange)   { double("Exchange") }

  subject { publisher.publish("bar".to_json) }

  before do
    allow_message_expectations_on_nil
    bunny_mock = nil
    allow(Bunny).to receive(:new).and_return bunny_mock
    allow(bunny_mock).to receive(:start).and_return true
    allow(bunny_mock).to receive(:close)
    allow(bunny_mock).to receive(:create_channel).and_return channel
    allow(channel).to receive(:exchange)
      .with("gundog", {:type=>:direct, :durable=>true, :auto_delete=>false})
      .and_return(exchange)
    allow(Time).to receive(:zone)
      .and_return(ActiveSupport::TimeZone.new("Europe/Berlin"))
    allow(exchange).to receive(:publish)
  end

  it "publishes messages on the exchange object" do
    subject

    expect(exchange).to have_received(:publish)
      .with("\"bar\"", {:heartbeat=>2, :exchange=>"gundog",
                        :prefetch=>1, :retry_timeout=>10, :max_retry=>3,
                        :exchange_options=>{:type=>:direct, :durable=>true,
                                            :auto_delete=>false},
                        :queue_options=>{:exclusive=>false, :ack=>true,
                                          :durable=>true},
                        :routing_key=>nil})
  end
end
