require 'helper'

class TestBundle < Minitest::Test
  describe 'batch' do
    before do
      Sidekiq.redis { |c| c.flushdb }
      @item = { 'class' => 'TestWorker' }
    end

    describe '#append' do
      it 'appends to the list of bundles' do
        Sidekiq::Paquet::Bundle.append(@item)
        assert_equal 1, Sidekiq.redis { |c| c.zcard 'bundles' }
        assert_equal 'TestWorker', Sidekiq.redis { |c| c.zrange('bundles', 0, -1).first }
      end

      it 'appends the args to the bundle queue' do
        @item.merge!({ 'args' => ['foo', 1], 'queue' => 'default' })
        list = Sidekiq::Paquet::Bundle.new('TestWorker')

        Sidekiq::Paquet::Bundle.append(@item)
        arg = list.items.first

        assert_equal 1, list.size
        assert_equal ['foo', 1], Sidekiq.load_json(arg)
      end
    end

    describe '#enqueue_jobs' do
      before do
        @queue = Sidekiq::Queue.new('default')
        items = [
          { 'class' => 'TestWorker', 'args' => ['foo', 1], 'queue' => 'default' },
          { 'class' => 'TestWorker', 'args' => ['bar', 3], 'queue' => 'default' }
        ]
        items.each { |i| Sidekiq::Paquet::Bundle.append(i) }
      end

      it 'enqueues regular job with bundle arguments' do
        Sidekiq::Paquet::Bundle.enqueue_jobs

        assert_equal 1, @queue.size
        @queue.each do |job|
          assert_equal [['foo', 1], ['bar', 3]], job.args
          assert_equal 'default', job.queue
        end
      end

      it 'removes items in the bundle queue after processing' do
        list = Sidekiq::Paquet::Bundle.new('TestWorker')
        assert_equal 2, list.size
        Sidekiq::Paquet::Bundle.enqueue_jobs
        assert_equal 0, list.size
      end

      it 'allows a custom bundle size' do
        begin
          opts = TestWorker.get_sidekiq_options
          TestWorker.sidekiq_options_hash = opts.merge('bundle_size' => 1)
          Sidekiq::Paquet::Bundle.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          TestWorker.sidekiq_options_hash = opts
        end
      end

      it 'uses the default bundle size if none is provided' do
        begin
          old = Sidekiq::Paquet.options[:default_bundle_size]
          Sidekiq::Paquet.options[:default_bundle_size] = 1

          Sidekiq::Paquet::Bundle.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          Sidekiq::Paquet.options[:default_bundle_size] = old
        end
      end

      it 'allows a minimum flush interval' do
        begin
          opts = TestWorker.get_sidekiq_options
          TestWorker.sidekiq_options_hash = opts.merge('minimum_execution_interval' => 10)

          Sidekiq::Paquet::Bundle.enqueue_jobs
          assert_equal 1, @queue.size

          Sidekiq::Paquet::Bundle.append({
            'class' => 'TestWorker', 'args' => ['foo', 1], 'queue' => 'default'
          })

          Sidekiq::Paquet::Bundle.enqueue_jobs
          assert_equal 1, @queue.size

          # Simulate key expiration in redis
          Sidekiq.redis { |c| c.del('bundle:TestWorker:next') }

          Sidekiq::Paquet::Bundle.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          TestWorker.sidekiq_options_hash = opts
        end
      end
    end
  end
end
