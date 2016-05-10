class TransactionlessWorker < Gundog::ApplicationWorker

  disable_transaction!

  def call
    puts "#{Time.zone.now.to_s}  processing #{json} with object #{self.object_id}"
  end
end
