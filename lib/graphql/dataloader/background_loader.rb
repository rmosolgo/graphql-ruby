# frozen_string_literal: true
begin
  require "concurrent"
rescue LoadError
  raise LoadError, "GraphQL::Dataloader::BackgroundLoader requires concurrent-ruby, add `gem \"concurrent-ruby\"` to your gemfile, `bundle install`, then try again!"
end

module GraphQL
  class Dataloader
    # A loader whose `#perform` will run on a background thread.
    #
    # It uses `Concurrent::Future` which uses a global thread pool.
    # @return [Concurrent::Future]
    class BackgroundLoader < GraphQL::Dataloader::Loader
      def sync
        Concurrent::Future.execute do
          super
        end
      end
    end
  end
end
