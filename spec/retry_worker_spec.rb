require "spec_helper"
require "gundog/retry_worker"

describe Gundog::RetryWorker do
  include_context :bunny_connection

  let(:retry_worker)      { described_class.new(0, 3) }
  let(:retry_metadata)    { Hash[:content_type=>"application/octet-stream",
                                 :delivery_mode=>2,
                                 :headers=>{:retry_count=>1},
                                 :priority=>0].with_indifferent_access }
  let(:no_retry_metadata) { Hash[:content_type=>"application/octet-stream",
                                 :delivery_mode=>2,
                                 :headers=>{:retry_count=>4},
                                 :priority=>0].with_indifferent_access }
  let(:delivery_info)     {
    OpenStruct.new(consumer_tag: "amq.ctag-ATWR0yHmT_c8A",
                   routing_key:  "test_queue_retry",
                   delivery_tag: {:exchange=>"gundog",
                                  :routing_key=>"test_queue_retry"}) }


  context "max retry limit is not exceeded" do
    subject {
      retry_worker.call("foo".to_json, retry_metadata, delivery_info, channel) }

    it "publishes the message back to normal queue with increased count" do
      subject

      sleep(1)
      expect(exchange).to have_received(:publish)
        .with("\"foo\"", {:heartbeat=>2, :exchange=>"gundog",
                          :prefetch=>100, :retry_timeout=>10, :max_retry=>3,
                          :workers=>1,
                          :exchange_options=>{:type=>:direct, :durable=>true,
                                              :auto_delete=>false},
                          :queue_options=>{:exclusive=>false, :ack=>true,
                                           :durable=>true},
                          :headers=>{:retry_count=>2},
                          :routing_key=>"test_queue"})
    end
  end

  context "max retry limit is exceeded" do
    subject { retry_worker.call("foo".to_json,
                                no_retry_metadata,
                                delivery_info,
                                channel) }

    it "publishes the message to the error queue without count" do
      subject

      sleep(1)
      expect(exchange).to have_received(:publish)
        .with("\"foo\"", {:heartbeat=>2, :exchange=>"gundog",
                          :prefetch=>100, :retry_timeout=>10, :max_retry=>3,
                          :workers=>1,
                          :exchange_options=>{:type=>:direct, :durable=>true,
                                              :auto_delete=>false},
                          :queue_options=>{:exclusive=>false, :ack=>true,
                                           :durable=>true},
                          :routing_key=>"test_queue_error"})
    end
  end
end
