require 'concurrent/scheduled_task'

require 'sidekiq'
require 'sidekiq/paquet/version'

require 'sidekiq/paquet/bundle'
require 'sidekiq/paquet/middleware'
require 'sidekiq/paquet/flusher'

module Sidekiq
  module Paquet
    DEFAULTS = {
      default_bundle_size: 100,
      flush_interval: nil,
      average_flush_interval: 15,
      initial_wait: 10,
      compatibility_mode: false
    }

    def self.options
      @options ||= DEFAULTS.dup
    end

    def self.options=(opts)
      @options = opts
    end

    def self.compatibility_mode=(v)
      options[:compatibility_mode] = !!v
    end

    def self.initial_wait
      options[:initial_wait] + (10 * rand)
    end
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Paquet::Middleware
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Paquet::Middleware
  end

  config.on(:startup) do
    config.options[:paquet_flusher] = Sidekiq::Paquet::Flusher.new
    Concurrent::ScheduledTask.execute(Sidekiq::Paquet.initial_wait) {
      config.options[:paquet_flusher].start
    }
  end

  config.on(:shutdown) do
    config.options[:paquet_flusher].shutdown
  end
end
