# Gundog

Lightweight background processor framework for RabbitMQ & Rails applications, based on [bunny](http://rubybunny.info), [serverengine](https://github.com/fluent/serverengine) and [celluloid](https://celluloid.io).

## Design goals
  - Make all RabbitMQ-related stuff persistent/durable by default
  - Small API, make queue naming etc. automatic
  - Wrap any async actions in database transactions by default
  - Take care of connection pool issues with ActiveRecord by default
  - Use as less as possible internal RabbitMQ/Bunny APIs or headers

## Installation & usage

Add this line to your Rails application's Gemfile:

```ruby
gem 'gundog'
```

And then execute:

    $ bundle


In order to find your application's worker classes, create a file `config/workers.yml` with snake cased names of your worker classes, like this:  
```yaml
workers: &workers
  - test_queue_worker
  - concurrency_queue_worker
  - republish_worker

development:
  workers: *workers

test:
  workers: *workers

production:
  workers: *workers
```
This will automatically create 3 RabbitMQ queues for each worker: The actual worker queue, a retry queue and an error queue. They will be named according to the worker name, suffixed with "_queue". Not deliverable messages will be transfered to the "_retry"-queue, re-enqueued after the configured time span has passed and end up in the "_error"-queue after the configured retry count.

Next, create a file `config/initializers/gundog.rb` with the following content, replace the URLs to where your RabbitMQ server is running:  
```ruby
Gundog.setup(amqp: "amqp://guest:guest@rabbitmq:5672", vhost: "/")
```
The setup parameter hash can hold the following options, these are the default settings:
```ruby
{
 ## options regarding AMQP and bunny
 # 2 seconds hartbeat for connection
 heartbeat:   2,
 # name of the generated exchange 
 exchange:    "gundog",
 # how many messages should any consumer fetch from the queue?
 prefetch:    100,

 ## options regarding retry/requeue behaviour
 # seconds to wait before attempting re-enqueue
 retry_timeout: 10,
 # how often should the message be re-enqueued?
 max_retry: 3,

 ## options regarding serverengine
 # should the process be daemonized?
 daemonize: false,
 # if daemonized: path to process id file
 pid_path: "gundog.pid",
 # path to log file or stdout
 log: STDOUT,
 # number of serverengine process workers
 workers: 1,

 ## options regarding AMQP exchange and queue settings
 exchange_options: { type: :direct, durable: true, auto_delete: false },
 queue_options: { exclusive: false, ack: true, durable: true } }
```

To create a worker, inherit your class from `Gundog::ApplicationWorker`.
```ruby
class MyWorker < Gundog::ApplicationWorker

  private

  attr_reader :record, :important_data

  def setup
    @record         = MyModel.find_by(id: json["model_id"].to_i)
    @important_data = MyCalcService.calc(@record)
  end

  def call
    MyUpdateService.call(record, important_data)
  end
end
```
This gives you a couple of methods and instance variables:  
You can use any record finding or instance variable setting in the `setup` method. Everything inside the `call` method will be run asynchronously. To disable wrapping the contents of the `call` method in a database transaction invoke the `disable_transaction!` class method.  
Every worker class has a instance variable called `json` by default which contains the deserialized payload of the message to be processed.  
Every worker can publish messages via the `publish_to(queue_name, data)` method. The data will automatically be serialized.  

The rake task `gundog:run` will start the server, creating all necessary queues and exchanges.


## Testing
A complete application integrating gundog can be found under http://github.com/alihuber/worker_playground. Any serious testing is done here.  
The RSpec tests in this repo stubbed everything away and only check for correct message passing.

## Roadmap
  - Better logging solution
  - Standalone version for usage outside of Rails
  - Add support for delayed messages (like delayed_job's `run_at` method)


## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/alihuber/gundog.


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
