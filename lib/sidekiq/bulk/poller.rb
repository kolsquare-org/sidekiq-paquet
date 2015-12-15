require 'sidekiq/util'
require 'sidekiq/scheduled'

module Sidekiq
  module Bulk
    class Poller < Sidekiq::Scheduled::Poller

      def initialize
        @sleeper  = ConnectionPool::TimedStack.new
        @done     = false
      end

      def start
        @thread ||= safe_thread("bulk") do
          initial_wait

          while !@done
            enqueue
            wait
          end
          Sidekiq.logger.info("Bulk exiting...")
        end
      end

      def enqueue
        begin
          Batch.enqueue_jobs
        rescue => ex
          # Most likely a problem with redis networking.
          # Punt and try again at the next interval
          logger.error ex.message
          logger.error ex.backtrace.first
        end
      end
    end
  end
end
