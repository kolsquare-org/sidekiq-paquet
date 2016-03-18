require 'sidekiq/web'

module Sidekiq
  module Paquet
    module Web
      VIEWS = File.expand_path('views', File.dirname(__FILE__))

      def self.registered(app)
        app.get '/paquet' do
          @lists = Sidekiq.redis { |c| c.zrange('bulks', 0, -1) }.map { |n| List.new(n) }
          erb File.read(File.join(VIEWS, 'index.erb'))
        end
      end

    end
  end
end

Sidekiq::Web.register(Sidekiq::Paquet::Web)
Sidekiq::Web.tabs['Grouping'] = 'paquet'
