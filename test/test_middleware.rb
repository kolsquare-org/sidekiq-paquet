require 'helper'

class TestMiddleware < Minitest::Test
  class BulkWorker
    include Sidekiq::Worker
    sidekiq_options bulk: true
  end

  class RegularWorker
    include Sidekiq::Worker
  end

  describe 'middleware' do
    before do
      Sidekiq.redis { |c| c.flushdb }
      @chain = Sidekiq::Middleware::Chain.new
      @chain.add Sidekiq::Bulk::Middleware
    end

    it 'yields if the worker does not use bulk process' do
      result = nil
      @chain.invoke(RegularWorker.new, {}, 'default') { result = true }
      assert_equal true, result
    end

    it 'does not yield and append to batch if worker uses bulk' do
      result = nil
      list   = Sidekiq::Bulk::List.new(BulkWorker.name)

      @chain.invoke(BulkWorker.new, {}, 'default') { result = true }

      assert_nil result
      assert_equal 1, list.size
    end
  end
end
