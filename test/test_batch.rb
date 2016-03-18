require 'helper'

class TestBatch < Minitest::Test
  describe 'batch' do
    before do
      Sidekiq.redis { |c| c.flushdb }
      @item = { 'class' => 'TestWorker' }
    end

    describe '#append' do
      it 'appends to the list of bulks' do
        Sidekiq::Paquet::Batch.append(@item)
        assert_equal 1, Sidekiq.redis { |c| c.zcard 'bulks' }
        assert_equal 'TestWorker', Sidekiq.redis { |c| c.zrange('bulks', 0, -1).first }
      end

      it 'appends the args to the bulk queue' do
        @item.merge!({ 'args' => ['foo', 1], 'queue' => 'default' })
        list = Sidekiq::Paquet::List.new('TestWorker')

        Sidekiq::Paquet::Batch.append(@item)
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
        items.each { |i| Sidekiq::Paquet::Batch.append(i) }
      end

      it 'enqueues regular job with bulk arguments' do
        Sidekiq::Paquet::Batch.enqueue_jobs

        assert_equal 1, @queue.size
        @queue.each do |job|
          assert_equal [['foo', 1], ['bar', 3]], job.args
          assert_equal 'default', job.queue
        end
      end

      it 'removes items in the bulk queue after processing' do
        list = Sidekiq::Paquet::List.new('TestWorker')
        assert_equal 2, list.size
        Sidekiq::Paquet::Batch.enqueue_jobs
        assert_equal 0, list.size
      end

      it 'allows a custom bulk size' do
        begin
          opts = TestWorker.get_sidekiq_options
          TestWorker.sidekiq_options_hash = opts.merge('bulk_size' => 1)
          Sidekiq::Paquet::Batch.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          TestWorker.sidekiq_options_hash = opts
        end
      end

      it 'uses the default bulk size if none is provided' do
        begin
          old = Sidekiq::Paquet.options[:default_bulk_size]
          Sidekiq::Paquet.options[:default_bulk_size] = 1

          Sidekiq::Paquet::Batch.enqueue_jobs
          assert_equal 2, @queue.size
        ensure
          Sidekiq::Paquet.options[:default_bulk_size] = old
        end
      end

      it 'allows a minimum flush interval' do
        begin
          opts = TestWorker.get_sidekiq_options
          TestWorker.sidekiq_options_hash = opts.merge('bulk_minimum_interval' => 10)

          Time.stub :now, 200 do
            Sidekiq::Paquet::Batch.enqueue_jobs
            assert_equal 1, @queue.size
          end

          Sidekiq::Paquet::Batch.append({
            'class' => 'TestWorker', 'args' => ['foo', 1], 'queue' => 'default'
          })

          Time.stub :now, 205 do
            Sidekiq::Paquet::Batch.enqueue_jobs
            assert_equal 1, @queue.size
          end

          Time.stub :now, 215 do
            Sidekiq::Paquet::Batch.enqueue_jobs
            assert_equal 2, @queue.size
          end
        ensure
          TestWorker.sidekiq_options_hash = opts
        end
      end
    end
  end
end
