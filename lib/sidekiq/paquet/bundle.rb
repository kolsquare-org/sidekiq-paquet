module Sidekiq
  module Paquet
    class Bundle

      def self.append(item)
        worker_name = item['class'.freeze]
        args = item.fetch('args'.freeze, [])

        Sidekiq.redis do |conn|
          conn.multi do
            if Paquet.options[:compatibility_mode]
              conn.zadd('bundles'.freeze, 0, worker_name)
            else
              conn.zadd('bundles'.freeze, 0, worker_name, nx: true)
            end
            conn.rpush("bundle:#{worker_name}", Sidekiq.dump_json(args))
          end
        end
      end

      def self.enqueue_jobs
        now = Time.now.to_f
        Sidekiq.redis do |conn|
          workers = conn.zrangebyscore('bundles'.freeze, '-inf', now)

          workers.each do |worker|
            klass = worker.constantize
            opts  = klass.get_sidekiq_options
            min_interval = opts['minimum_execution_interval'.freeze]

            items = conn.lrange("bundle:#{worker}", 0, -1)
            items.map! { |i| Sidekiq.load_json(i) }

            items.each_slice(opts.fetch('bundle_size'.freeze, Paquet.options[:default_bundle_size])) do |vs|
              Sidekiq::Client.push(
                'class' => worker,
                'queue' => opts['queue'.freeze],
                'args'  => vs
              )
            end

            conn.ltrim("bundle:#{worker}", items.size, -1)
            conn.zadd('bundles'.freeze, now + min_interval, worker) if !Paquet.options[:compatibility_mode] && min_interval
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
