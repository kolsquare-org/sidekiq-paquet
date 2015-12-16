require 'helper'

class TestBatch < Minitest::Test
  describe 'batch' do
    before do
      Sidekiq.redis { |c| c.flushdb }
    end

    describe '#append' do
      it 'appends to the list of bulks' do
        Sidekiq::Bulk::Batch.append('TestWorker', {}, nil)
        assert_equal 1, Sidekiq.redis { |c| c.scard 'bulks' }
      end

      it 'appends the args to the bulk queue' do
        item = { 'class' => 'TestWorker', 'args' => ['foo', 1], 'queue' => 'default' }
        list = Sidekiq::Bulk::List.new('TestWorker')

        Sidekiq::Bulk::Batch.append('TestWorker', item, nil)
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
        items.each { |i| Sidekiq::Bulk::Batch.append('TestWorker', i, nil) }
      end

      it 'enqueues regular job with bulk arguments' do
        Sidekiq::Bulk::Batch.enqueue_jobs

        assert_equal 1, @queue.size
        @queue.each do |job|
          assert_equal [['foo', 1], ['bar', 3]], job.args
          assert_equal 'default', job.queue
        end
      end

      it 'removes items in the bulk queue after processing' do
        list = Sidekiq::Bulk::List.new('TestWorker')
        assert_equal 2, list.size
        Sidekiq::Bulk::Batch.enqueue_jobs
        assert_equal 0, list.size
      end

      it 'allows a custom bulk size' do
        begin
          opts = TestWorker.get_sidekiq_options
          TestWorker.sidekiq_options_hash = opts.merge('bulk_size' => 1)
          Sidekiq::Bulk::Batch.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          TestWorker.sidekiq_options_hash = opts
        end
      end

      it 'uses the default bulk size if none is provided' do
        begin
          old, Sidekiq::Bulk.default_bulk_size = Sidekiq::Bulk.default_bulk_size, 1
          Sidekiq::Bulk::Batch.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          Sidekiq::Bulk.default_bulk_size = old
        end
      end
    end
  end
end
