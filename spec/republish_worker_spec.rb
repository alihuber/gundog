require "spec_helper"
require_relative "republish_worker"

describe Gundog::ApplicationWorker do
  include_context :bunny_connection

  # ApplicationWorker is never used directly, subclassed
  let(:work_actor)     { RepublishWorker.new }
  let(:metadata)       { Hash[:content_type=>"application/octet-stream",
                              :delivery_mode=>2,
                              :priority=>0] }
  let(:delivery_info)  {
    OpenStruct.new(consumer_tag: "amq.ctag-ATWR0yHmT_c8A",
                   delivery_tag:  {:exchange=>"gundog",
                                   :routing_key=>"test_queue"}) }

  subject { work_actor.work("foo".to_json, metadata, delivery_info, channel) }

  it "can publish arbitrary messages by itself" do
    subject
    expect(exchange).to have_received(:publish)
      .with("\"foo\"", {:heartbeat=>2, :exchange=>"gundog",
                        :prefetch=>100, :retry_timeout=>10, :max_retry=>3,
                        :workers=>1,
                        :exchange_options=>{:type=>:direct, :durable=>true,
                                            :auto_delete=>false},
                        :queue_options=>{:exclusive=>false, :ack=>true,
                                         :durable=>true},
                        :routing_key=>"test_queue_retry"})
  end
end
