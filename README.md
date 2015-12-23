# Sidekiq::Bulk

Instead of processing similar sidekiq jobs one at a time, process them in bulk.
Useful for grouping background API calls or intensive database inserts.

## Installation

```ruby
gem install 'sidekiq-bulk'
```

sidekiq-bulk requires sidekiq 4+. If you're using sidekiq < 4, you can check [sidekiq-grouping](https://github.com/gzigzigzeo/sidekiq-grouping/) for similar features.

## Usage

Add `bulk` options to your worker's `sidekiq_options` to have them processed in bulk. The size of the bulk can also be configured per worker. If not, the `Sidekiq::Bulk.options[:default_bulk_size]` is used.

```ruby
class ElasticIndexerWorker
  include Sidekiq::Worker

  sidekiq_options bulk: true, bulk_size: 100

  def perform(values)
    # Perform work with the array of values
  end
end
```

Instead of being processed normally by sidekiq, jobs' arguments will be stored into a separate queue and periodically, a poller will retrieve these arguments and enqueue a regular sidekiq job with grouped args.
Thus, your worker will only be invoked with an array of values, never with separate values themselves.

For example, if you call `perform_async` twice on the previous worker

```ruby
ElasticIndexerWorker.perform_async({ delete: { _index: 'users', _id: 1, _type: 'user' } })
ElasticIndexerWorker.perform_async({ delete: { _index: 'users', _id: 2, _type: 'user' } })
```

the worker instance will receive these values as a single argument

```ruby
[
  { delete: { _index: 'users', _id: 1, _type: 'user' } },
  { delete: { _index: 'users', _id: 2, _type: 'user' } }
]
```

## Configuration

You can change global configuration by modifying the `Sidekiq::Bulk.options` hash.

```
  Sidekiq::Bulk.options[:default_bulk_size] = 500 # Default is 100
  Sidekiq::Bulk.options[:average_bulk_flush_interval] = 30 # Default is 15
```

The `average_bulk_flush_interval` represent the average time elapsed between two polling of values. This scales with the number of sidekiq processes you're running. So if you have 5 sidekiq processes, and set the `average_bulk_flush_interval` to 15, each process will check for new bulk jobs every 75 seconds -- in average the bulk queue will be checked every 15 seconds.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ccocchi/sidekiq-bulk. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
