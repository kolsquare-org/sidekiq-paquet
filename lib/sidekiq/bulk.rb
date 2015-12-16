require 'sidekiq'
require 'sidekiq/bulk/version'

require 'sidekiq/bulk/list'
require 'sidekiq/bulk/batch'
require 'sidekiq/bulk/middleware'
require 'sidekiq/bulk/poller'

module Sidekiq
  module Bulk
    def self.default_bulk_size
      @default_bulk_size ||= 100
    end

    def self.default_bulk_size=(value)
      @default_bulk_size = value
    end
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add Sidekiq::Bulk::Middleware
  end

  config.server_middleware do |chain|
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
