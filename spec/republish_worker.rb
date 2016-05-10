class RepublishWorker < Gundog::ApplicationWorker

  def call
    publish_to("test_queue_retry", "foo")
  end
end
