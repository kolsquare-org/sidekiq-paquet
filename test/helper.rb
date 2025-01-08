$TESTING = true
ENV['RACK_ENV'] = ENV['RAILS_ENV'] = 'test'

require 'minitest/autorun'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/paquet'

REDIS_URL = ENV['REDIS_URL'] || 'redis://localhost/15'
Sidekiq.configure_client do |config|
  config.redis = { url: REDIS_URL }
  config.logger.level = Logger::ERROR
end

class TestWorker
  include Sidekiq::Worker
end
