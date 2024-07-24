# Sidekiq::Paquet

Instead of enqueueing and processing jobs one at a time, enqueue them one by one and process them in bulk.
Useful for grouping background API calls or intensive database inserts coming from multiple sources.

## Installation

```ruby
gem install 'sidekiq-paquet'
```

sidekiq-paquet requires Sidekiq 4+.

## Usage

Add `bundled: true` option to your worker's `sidekiq_options` to have jobs processed in bulk. The size of the bundle can be configured per worker. If not specified, the `Sidekiq::Paquet.options[:default_bundle_size]` is used.

```ruby
class ElasticIndexerWorker
  include Sidekiq::Worker

  sidekiq_options bundled: true, bundle_size: 100

  def perform(*values)
    # Perform work with the array of values
  end
end
```

Instead of being processed by Sidekiq right away, jobs will be stored into a separate queue and periodically, a separate thread will pick up this internal queue, slice `bundle_size` elements into an array and enqueue a regular Sidekiq job with that bundle as argument.
Thus, your worker will only be invoked with an array of values, never with single values themselves.

For example, if you call `perform_async` twice on the previous worker

```ruby
ElasticIndexerWorker.perform_async({ delete: { _index: 'users', _id: 1, _type: 'user' } })
ElasticIndexerWorker.perform_async({ delete: { _index: 'users', _id: 2, _type: 'user' } })
```

the worker instance will receive these values as a single argument

```ruby
[
  [{ delete: { _index: 'users', _id: 1, _type: 'user' } }],
  [{ delete: { _index: 'users', _id: 2, _type: 'user' } }]
]
```

Every time flushing happens, `sidekiq-paquet` will try to process all your workers marked as bundled. If you want to limit the time between two flushing in a worker, you can pass the `minimum_execution_interval` option to sidekiq options.

## Configuration

You can change global configuration by modifying the `Sidekiq::Paquet.options` hash.

```
  Sidekiq::Paquet.options[:default_bundle_size] = 500 # Default is 100
  Sidekiq::Paquet.options[:average_flush_interval] = 30 # Default is 15
```

The `average_flush_interval` represent the average time elapsed between two polling of values. This scales with the number of sidekiq processes you're running. So if you have 5 sidekiq processes, and set the `average_flush_interval` to 15, each process will check for new bundled jobs every 75 seconds -- so that in average, the bundles queue will be checked every 15 seconds.

## Errors handling
You can catch all errors occuring inside one of the flushing process by passing an error handler block to `error_handlers` option in sidekiq paquet options.
```ruby
  Sidekiq::Paquet.options[:error_handlers] << ->(e) { 
    # Do something with the exception ...
  }
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ccocchi/sidekiq-paquet. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
