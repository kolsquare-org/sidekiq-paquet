module Sidekiq
  module Bulk
    class List
      def initialize(name)
        @lname = "bulk:#{name}"
      end

      def size
        Sidekiq.redis { |c| c.llen(@lname) }
      end

      def items
        Sidekiq.redis { |c| c.lrange(@lname, 0, -1) }
      end
    end
  end
end
