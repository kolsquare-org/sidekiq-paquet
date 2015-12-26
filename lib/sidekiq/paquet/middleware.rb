module Sidekiq
  module Paquet
    class Middleware
      def call(worker, item, queue, redis_pool = nil)
        if item['bulk'.freeze]
          Batch.append(item)
          false
        else
          yield
        end
      end
    end
  end
end
