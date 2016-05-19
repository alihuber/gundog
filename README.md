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
Next, create a file `config/initializers/gundog.rb` with the following content, replace the URLs to where your RabbitMQ server is running:  
```ruby
Gundog.setup(amqp: "amqp://guest:guest@rabbitmq:5672", vhost: "/")
```

TODO: list configuration options  

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
You can use any record finding or instance variable setting in the `setup` method. Everything inside the call method will be run asynchronously. To disable wrapping the contents of the call method in a database transaction call the `disable_transaction!` class method.  
Every worker class has a instance variable called `json` by default which contains the deserialized payload of the message to be processed.  
Every worker can publish messages via the `publish_to(queue_name, data)` method. The data will automatically be serialized.  

The rake task `gundog:run` will start the server, creating all necessary queues and exchanges.


## Testing
A complete application integrating gundog can be found under http://github.com/alihuber/worker_playground. Any serious testing is done here.  
The RSpec tests in this repo stubbed everything away and only check for correct message passing.


## Roadmap
  - More docs
  - Less dependency on Rails (best would be a complete separated Rails mode)
  - Add support for delayed messages (like delayed_job's `run_at` method)


## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/alihuber/gundog.


## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
