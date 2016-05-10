class TestQueueWorker < Gundog::ApplicationWorker

  def call
    i = json.to_i
    if i == 2
      raise RuntimeError, "Error!"
    else
      puts "#{Time.zone.now.to_s}  processing #{json} with object #{self.object_id}"
    end
  end
end
