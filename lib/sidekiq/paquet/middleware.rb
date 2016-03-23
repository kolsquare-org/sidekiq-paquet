module Sidekiq
  module Paquet
    class Middleware
      def call(worker, item, queue, redis_pool = nil)
        if item['bundled'.freeze]
          Bundle.append(item)
          false
        else
          yield
        end
      end
    end
  end
end
