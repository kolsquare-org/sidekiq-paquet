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
        @thread ||= safe_thread('bulk') do
          initial_wait

          while !@done
            enqueue
            wait
          end
          Sidekiq.logger.info('Bulk exiting...')
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

      private

      # Calculates a random interval that is ±50% the desired average.
      def random_poll_interval
        avg = poll_interval_average.to_f
        avg * rand + avg / 2
      end

      # We do our best to tune the poll interval to the size of the active Sidekiq
      # cluster.  If you have 30 processes and poll every 15 seconds, that means one
      # Sidekiq is checking Redis every 0.5 seconds - way too often for most people
      # and really bad if the retry or scheduled sets are large.
      #
      # Instead try to avoid polling more than once every 15 seconds.  If you have
      # 30 Sidekiq processes, we'll poll every 30 * 15 or 450 seconds.
      # To keep things statistically random, we'll sleep a random amount between
      # 225 and 675 seconds for each poll or 450 seconds on average.  Otherwise restarting
      # all your Sidekiq processes at the same time will lead to them all polling at
      # the same time: the thundering herd problem.
      #
      # We only do this if poll_interval_average is unset (the default).
      def poll_interval_average
        if Sidekiq::Bulk.options[:dynamic_interval_scaling]
          scaled_poll_interval
        else
          Sidekiq::Bulk.options[:bulk_flush_interval] ||= scaled_poll_interval
        end
      end

      # Calculates an average poll interval based on the number of known Sidekiq processes.
      # This minimizes a single point of failure by dispersing check-ins but without taxing
      # Redis if you run many Sidekiq processes.
      def scaled_poll_interval
        pcount = Sidekiq::ProcessSet.new.size
        pcount = 1 if pcount == 0
        pcount * Sidekiq::Bulk.options[:average_bulk_flush_interval]
      end

      def initial_wait
        # Have all processes sleep between 5-15 seconds.  10 seconds
        # to give time for the heartbeat to register (if the poll interval is going to be calculated by the number
        # of workers), and 5 random seconds to ensure they don't all hit Redis at the same time.
        total = INITIAL_WAIT + (15 * rand)
        @sleeper.pop(total)
      rescue Timeout::Error
      end
    end
  end
end
