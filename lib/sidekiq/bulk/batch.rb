module Sidekiq
  module Bulk
    module Batch

      def self.append(worker_name, item, queue)
        args = item.fetch('args', [])

        Sidekiq.redis do |conn|
          conn.multi do
            conn.sadd('bulks'.freeze, worker_name)
            conn.rpush("bulk:#{worker_name}", Sidekiq.dump_json(args))
          end
        end
      end

      def self.enqueue_jobs
        Sidekiq.redis do |conn|
          workers = conn.smembers('bulks'.freeze)

          workers.each do |worker|
            klass = worker.constantize
            opts  = klass.get_sidekiq_options.fetch('bulk'.freeze, {})
            items = conn.lrange("bulk:#{worker}", 0, -1)
            items.map! { |i| Sidekiq.load_json(i) }

            items.each_slice(opts.fetch(:size, 10)) do |vs|
              Sidekiq::Client.push(
                'class' => worker,
                'queue' => opts['queue'.freeze],
                'args'  => vs
              )
            end

            conn.ltrim("bulk:#{worker}", items.size, -1)
          end
        end
      end

    end
  end
end
