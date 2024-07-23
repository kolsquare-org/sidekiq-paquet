require 'concurrent/timer_task'

module Sidekiq
  module Paquet
    class Flusher

      def initialize
        @task  = Concurrent::TimerTask.new(
          execution_interval: execution_interval) { Bundle.enqueue_jobs }
      end

      def start
        Sidekiq.logger.info('Starting paquet flusher 🚀')
        @task.execute
      end

      def shutdown
        Sidekiq.logger.info('Paquet flusher exiting...')
        @task.shutdown
      end

      private

      # To avoid having all processes flushing at the same time, randomize
      # the execution interval between 0.5-1.5 the scaled interval, so that
      # on average, interval is respected.
      #
      def execution_interval
        avg = scaled_interval.to_f
        avg * rand + avg / 2
      end

      # Scale interval with the number of Sidekiq processes running. Each one
      # is going to run a flusher instance. If you have 10 processes and an
      # average flush interval of 10s, it means one process is flushing every
      # second, which is wasteful and beats the purpose of bundling.
      #
      # To avoid this, we scale the average flush interval with the number of
      # Sidekiq processes running, i.e instead of flushing every 10s, let every
      # process flush every 100 seconds.
      #
      def scaled_interval
        Sidekiq::Paquet.options[:flush_interval] ||= begin
          pcount = Sidekiq::ProcessSet.new.size
          pcount = 1 if pcount == 0 # Maybe raise here
          pcount * Sidekiq::Paquet.options[:average_flush_interval]
        end
      end
    end
  end
end
