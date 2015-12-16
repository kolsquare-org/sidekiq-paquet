require 'sidekiq'
require 'sidekiq/bulk/version'

require 'sidekiq/bulk/list'
require 'sidekiq/bulk/batch'
require 'sidekiq/bulk/middleware'
require 'sidekiq/bulk/poller'

module Sidekiq
  module Bulk
    DEFAULTS = {
      default_bulk_size: 100,
      bulk_flush_interval: nil,
      average_bulk_flush_interval: 15,
      dynamic_interval_scaling: true
    }

    def self.options
      @options ||= DEFAULTS.dup
    end

    def self.options=(opts)
      @options = opts
    end
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Bulk::Middleware
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Bulk::Middleware
  end

  config.on(:startup) do
    config.options[:bulk_poller] = Sidekiq::Bulk::Poller.new
    config.options[:bulk_poller].start
  end

  config.on(:shutdown) do
    config.options[:bulk_poller].terminate
  end
end
