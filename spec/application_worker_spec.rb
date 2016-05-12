require "spec_helper"
require_relative "test_queue_worker"

describe Gundog::ApplicationWorker do
  include_context :bunny_connection

  # ApplicationWorker is never used directly, subclassed

  let(:work_actor)     { TestQueueWorker.new }
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

    it "executes worker call in transaction" do
      subject

      expect(ActiveRecord::Base).to have_received(:transaction)
    end
  end


  context "call is not successful for the first time" do
    subject { work_actor.work("2".to_json, metadata, delivery_info, channel) }

    it "re-publishes the message with retry_count set to 1" do
      subject

      expect(exchange).to have_received(:publish)
        .with("\"2\"", {:heartbeat=>2, :exchange=>"gundog",
                        :prefetch=>100, :retry_timeout=>10, :max_retry=>3,
                        :workers=>1, :daemonize=>false, :log=>STDOUT,
                        :pid_path=>"gundog.pid",
                        :exchange_options=>{:type=>:direct, :durable=>true,
                                            :auto_delete=>false},
                        :queue_options=>{:exclusive=>false, :ack=>true,
                                         :durable=>true},
                        :headers=>{:retry_count=>1},
                        :routing_key=>"test_queue_retry"})
    end

    # successful or not, the message is acknowledged and published to retry
    it "acknowledges the message" do
      subject

      expect(channel)
        .to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    end
  end

  context "call is not successful for the first time" do

    subject {
      work_actor.work("2".to_json, metadata, delivery_info, channel) }

    it "re-publishes the message with retry_count set to 1" do
      subject

      expect(exchange).to have_received(:publish)
        .with("\"2\"", {:heartbeat=>2, :exchange=>"gundog",
                        :prefetch=>100, :retry_timeout=>10, :max_retry=>3,
                        :workers=>1, :daemonize=>false, :log=>STDOUT,
                        :pid_path=>"gundog.pid",
                        :exchange_options=>{:type=>:direct, :durable=>true,
                                            :auto_delete=>false},
                        :queue_options=>{:exclusive=>false, :ack=>true,
                                         :durable=>true},
                        :headers=>{:retry_count=>1},
                        :routing_key=>"test_queue_retry"})
    end

    # successful or not, the message is acknowledged and published to retry
    it "acknowledges the message" do
      subject

      expect(channel)
        .to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    end
  end

  context "call is not successful for consequent times" do
    subject {
      work_actor.work("2".to_json, retry_metadata, delivery_info, channel) }

    it "re-publishes the message with retry_count not altered" do
      subject

      expect(exchange).to have_received(:publish)
        .with("\"2\"", {:heartbeat=>2, :exchange=>"gundog",
                        :prefetch=>100, :retry_timeout=>10, :max_retry=>3,
                        :workers=>1, :daemonize=>false, :log=>STDOUT,
                        :pid_path=>"gundog.pid",
                        :exchange_options=>{:type=>:direct, :durable=>true,
                                            :auto_delete=>false},
                        :queue_options=>{:exclusive=>false, :ack=>true,
                                         :durable=>true},
                        :headers=>{:retry_count=>2},
                        :routing_key=>"test_queue_retry"})
    end

    # successful or not, the message is acknowledged and published to retry
    it "acknowledges the message" do
      subject

      expect(channel)
        .to have_received(:acknowledge).with(delivery_info.delivery_tag, false)
    end
  end
end
