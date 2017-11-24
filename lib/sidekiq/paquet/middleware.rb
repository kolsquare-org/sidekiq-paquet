module Sidekiq
  module Paquet
    class Middleware
      def call(worker, item, queue, redis_pool = nil)
        return yield if defined?(Sidekiq::Testing)

        retrying = item.key?('failed_at'.freeze)

        if item['bundled'.freeze] && !retrying
          Bundle.append(item)
          false
        else
          yield
        end
      end
    end
  end
end
