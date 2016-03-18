module Sidekiq
  module Paquet
    class List
      def initialize(name)
        @lname = "bulk:#{name}"
      end

      def queue
        worker_name.constantize.get_sidekiq_options['queue']
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
