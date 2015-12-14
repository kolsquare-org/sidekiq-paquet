module Sidekiq
  module Bulk
    class Middleware
      def call(worker, item, queue, redis_pool)
        sdkq_opts = worker.get_sidekiq_options

        if sdkq_opts.has_key?(:bulk)
          Batch.append(worker.name, item, queue, redis_pool)
          false
        else
          yield
        end
      end
    end
  end
end
