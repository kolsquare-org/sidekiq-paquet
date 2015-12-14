require 'sidekiq'
require 'sidekiq/bulk/version'

require 'sidekiq/bulk/batch'
require 'sidekiq/bulk/middleware'
require 'sidekiq/bulk/poller'

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
