$TESTING = true

require 'minitest/autorun'
require 'sidekiq/api'
require 'sidekiq/paquet'

Sidekiq.logger.level = Logger::ERROR

REDIS_URL = ENV['REDIS_URL'] || 'redis://localhost/15'
Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL, namespace: 'paquet' }
end

class TestWorker
  include Sidekiq::Worker
end
