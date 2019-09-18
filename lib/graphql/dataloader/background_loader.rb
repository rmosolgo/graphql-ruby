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
    class BackgroundLoader < GraphQL::Dataloader::Loader
      def sync
        Concurrent::Future.execute do
          setup_thread
          super
          teardown_thread
        end
      end

      # Implement this method to prepare any thread state that your
      # application depends on, for example, `Thread.current[:user] = @context[:current_user]`
      def setup_thread
      end

      # Implement this method to remove any setup added in `setup_thread`
      def teardown_thread
      end
    end
  end
end
