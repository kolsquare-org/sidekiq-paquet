module Sidekiq
  module Bulk
    class Middleware
      def call(worker, item, queue, redis_pool = nil)
        klass     = worker.class
        sdkq_opts = klass.get_sidekiq_options

        if sdkq_opts.has_key?('bulk'.freeze)
          Batch.append(klass.name, item, queue)
          false
        else
          yield
        end
      end
    end
  end
end
