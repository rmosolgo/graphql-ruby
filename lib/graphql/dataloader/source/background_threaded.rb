# frozen_string_literal: true

module GraphQL
  class Dataloader
    class Source
      # Include this module to make Source subclasses run their {#perform} methods inside `Concurrent::Promises.future { ... }`
      module BackgroundThreaded
        # Assert that concurrent-ruby is present
        def self.included(_child_class)
          if !defined?(Concurrent)
            raise "concurrent-ruby is required to use #{self}, add `gem 'concurrent-ruby', require: 'concurrent'` to your Gemfile and `bundle install`"
          end
        end

        private

        # This is called when populating the promise cache.
        # In this case, also register the source for async processing.
        # (It might have already been registered by another `key`, the dataloader will ignore it in that case.)
        def make_lazy(key)
          lazy = super
          Dataloader.current.enqueue_async_source(self)
          lazy
        end

        # Like the superclass method, but:
        #
        # - Wrap the call to `super` inside a `Concurrent::Promises::Future`
        # - In the meantime, `fulfill(...)` each key with a lazy that will wait for the future
        #
        # Interestingly, that future will `fulfill(...)` each key with a finished value, so only the first
        # of the Lazies will actually be called. (Since the others will be replaced.)
        def perform_with_error_handling(keys_to_load)
          this_dl = Dataloader.current
          future = Concurrent::Promises.delay do
            Dataloader.load(this_dl) do
              super(keys_to_load)
            end
          end

          keys_to_load.each do |key|
            lazy = GraphQL::Execution::Lazy.new do
              future.value # force waiting for it to be finished
              fulfilled_value_for(key)
            end
            fulfill(key, lazy)
          end
          # Actually kick off the future:
          future.touch
          nil
        end
      end
    end
  end
end
