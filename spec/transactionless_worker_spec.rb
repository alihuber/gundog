require "spec_helper"
require_relative "transactionless_worker"

describe Gundog::ApplicationWorker do
  include_context :bunny_connection

  # ApplicationWorker is never used directly, subclassed

  let(:work_actor)     { TransactionlessWorker.new }
  let(:metadata)       { Hash[:content_type=>"application/octet-stream",
                              :delivery_mode=>2,
                              :priority=>0] }
  let(:retry_metadata) { Hash[:content_type=>"application/octet-stream",
                              :delivery_mode=>2,
                              :headers=>{:retry_count=>2},
                              :priority=>0] }
  let(:delivery_info)  {
    OpenStruct.new(consumer_tag: "amq.ctag-ATWR0yHmT_c8A",
                   delivery_tag:  {:exchange=>"gundog",
                                   :routing_key=>"test_queue"}) }

  context "call is successful" do
    subject { work_actor.work("foo".to_json, metadata, delivery_info, channel) }

    it "does not throw an error" do
      expect { subject }.not_to raise_exception
    end

    it "acknowledges the message" do
      subject
      expect(channel)
        .to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    end

    it "does not execute worker call in transaction" do
      subject
      expect(ActiveRecord::Base).not_to have_received(:transaction)
    end
  end
end
