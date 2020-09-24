# frozen_string_literal: true

module GraphQL
  class Dataloader
    # Let's start with a close reading of promise.rb
    # Then improve it to match GraphQL-Ruby's requirements
    class Promise
      # @param source [<#wait>]
      def initialize(source, then_block: nil)
        @caller = caller(3, 1).first
        @source = source
        @then_block = then_block
        @pending_promises = nil
        @synced = false
        @value = nil
      end

      def inspect
        "#<#{self.class.name}##{object_id} from \"#{@caller}\" @value=#{@value.inspect}>"
      end

      def synced?
        @synced
      end

      attr_reader :value

      # TODO also reject?
      # TODO better api than `call_then = true`
      def fulfill(value, call_then = true )
        if @then_block && call_then
          value = @then_block.call(value)
        end

        debug { ["fulfill", self, value] }
        if @synced
          nil
        elsif value.is_a?(Dataloader::Promise)
          if value.synced?
            fulfill(value.value)
          else
            @source = value
            value.subscribe(self, false)
          end
        else
          @source = nil
          @synced = true
          @value = value
          @pending_promises&.each { |pr, call_then| pr.fulfill(value, call_then) }
          @pending_promises = nil
        end
      end

      def sync
        if !@synced
          wait
          debug { ["sync", self, @value] }
        end
        # TODO Also raise
        @value
      rescue GraphQL::Dataloader::LoadError => err
        local_err = err.dup
        query = Dataloader.current.current_query
        local_err.graphql_path = query.context[:current_path]
        op_name = query.selected_operation_name || query.selected_operation.operation_type || "query"
        local_err.message = err.message.sub("),", ") at #{op_name}.#{local_err.graphql_path.join(".")},")
        raise local_err
      end

      # resolve this promise's dependencies as long as one can be found
      # @return [void]
      def wait
        while (current_source = @source)
          current_source.wait
          # Only care if these are the same object,
          # which shows that the promise didn't start
          # waiting on something else
          if current_source.equal?(@source)
            break
          end
        end
      end

      def then(&block)
        new_promise = self.class.new(self, then_block: block)
        subscribe(new_promise)
        new_promise
      end

      def subscribe(other_promise, call_then = true )
        @pending_promises ||= []
        @pending_promises.push([other_promise, call_then])
      end

      def debug
        if ENV["DEBUG_PROMISE"]
          pp yield
        end
      end

      def self.all(maybe_promises)
        group = Group.new(maybe_promises)
        group.promise
      end

      class Group
        attr_reader :promise

        def initialize(maybe_promises)
          @promise = Promise.new(self)
          @maybe_promises = maybe_promises
          @waited = false
        end

        def wait
          if !@waited
            @waited = true
            results = @maybe_promises.map { |mp|
              if mp.respond_to?(:sync)
                mp.sync
                mp.value
              else
                mp
              end
            }
            promise.fulfill(results)
          end
        end
      end
    end
  end
end
