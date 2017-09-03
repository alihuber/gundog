shared_context :bunny_connection do
  let!(:channel)    { double("Channel") }
  let!(:publisher)  { instance_double ::Gundog::Publisher }
  let!(:exchange)   { double("Exchange") }
  let!(:connection) { double("Connection") }
  let!(:bunny_mock) { double("Bunny") }

  before do
    allow_message_expectations_on_nil
    allow(publisher).to receive(:publish)
    allow(Bunny).to receive(:new)
      .with(nil, {vhost: nil, heartbeat: 2})
      .and_return bunny_mock
    allow(bunny_mock).to receive(:start).and_return true
    allow(bunny_mock).to receive(:close)
    allow(bunny_mock).to receive(:create_channel).and_return channel
    allow(bunny_mock).to receive(:connected?).and_return true

    allow(channel).to receive(:acknowledge)
    allow(channel).to receive(:prefetch)
    allow(channel).to receive(:reject)
    allow(channel).to receive(:exchange)
      .with("gundog", {type: :direct, durable: true, auto_delete: false})
      .and_return(exchange)
    allow(exchange).to receive(:publish)
    allow(channel).to receive(:number)

    allow(Time).to receive(:zone)
      .and_return(ActiveSupport::TimeZone.new("Europe/Berlin"))

    allow(ActiveRecord::Base).to receive(:transaction) { |&block| block.call }
  end
end
