module Sidekiq
  module Paquet
    class Bundle

      def self.append(item)
        worker_name = item['class'.freeze]
        args = item.fetch('args'.freeze, [])

        Sidekiq.redis do |conn|
          conn.multi do
            conn.zadd('bundles'.freeze, 0, worker_name)
            conn.rpush("bundle:#{worker_name}", Sidekiq.dump_json(args))
          end
        end
      end

      def self.enqueue_jobs
        Sidekiq.redis do |conn|
          workers = conn.zrange('bundles'.freeze, 0, -1)

          workers.each do |worker|
            klass = Object.const_get(worker)
            opts  = klass.get_sidekiq_options
            min_interval = opts['minimum_execution_interval'.freeze]

            if min_interval
              next unless conn.set("bundle:#{worker}:next", 'queue'.freeze, nx: true, ex: min_interval)
            end

            items = conn.lrange("bundle:#{worker}", 0, 5000)
            items.map! { |i| Sidekiq.load_json(i) }

            bundle_size = opts['bundle_size'.freeze] || Paquet.options[:default_bundle_size]
            items.each_slice(bundle_size) do |vs|
              Sidekiq::Client.push(
                'class' => worker,
                'queue' => opts['queue'.freeze],
                'args'  => vs
              )

              vs.size.times { conn.lpop("bundle:#{worker}") }
            end
          end
        end
      end

      def initialize(name)
        @lname = "bundle:#{name}"
      end

      def queue
        worker_name.constantize.get_sidekiq_options['queue'.freeze]
      end

      def worker_name
        @lname.split(':').last
      end

      def size
        Sidekiq.redis { |c| c.llen(@lname) }
      end

      def items
        Sidekiq.redis { |c| c.lrange(@lname, 0, -1) }
      end

      def clear
        Sidekiq.redis { |c| c.del(@lname) }
      end

    end
  end
end
