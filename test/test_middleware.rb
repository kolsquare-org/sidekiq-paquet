require 'helper'

class TestMiddleware < Minitest::Test
  describe 'middleware' do
    before do
      Sidekiq.redis { |c| c.flushdb }
      @chain = Sidekiq::Middleware::Chain.new
      @chain.add Sidekiq::Paquet::ClientMiddleware
      @worker = Minitest::Mock.new
    end

    it 'yields the next item in the chain if the worker is not bundled' do
      result = nil
      @chain.invoke(@worker, {}, 'default') { result = true }
      assert_equal true, result
    end

    it 'stops the chain and append to batch if worker is bundled' do
      result = nil
      list   = Sidekiq::Paquet::Bundle.new('TestWorker')
      item   = { 'class' => 'TestWorker', 'bundled' => true }

      @chain.invoke(@worker, item, 'default') { result = true }

      assert_nil result
      assert_equal 1, list.size
    end
  end
end
