require 'helper'

class TestMiddleware < Minitest::Test
  describe 'middleware' do
    before do
      Sidekiq.redis { |c| c.flushdb }
      @chain = Sidekiq::Middleware::Chain.new
      @chain.add Sidekiq::Paquet::Middleware
      @worker = Minitest::Mock.new
    end

    it 'yields if the worker does not use bulk process' do
      result = nil
      @chain.invoke(@worker, {}, 'default') { result = true }
      assert_equal true, result
    end

    it 'does not yield and append to batch if worker uses bulk' do
      result = nil
      list   = Sidekiq::Paquet::List.new('TestWorker')
      item   = { 'class' => 'TestWorker', 'bulk' => true }

      @chain.invoke(@worker, item, 'default') { result = true }

      assert_nil result
      assert_equal 1, list.size
    end
  end
end
