# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class Cursor
      class SelfStack
        def initialize
          @stack = []
          @next_self = nil
        end

        def stage(next_self)
          if !@locked
            @next_self = next_self
          end
        end

        def push_staged
          if !@locked
            push_self(@next_self)
            @next_self = nil
          end
        end

        # Use this when you enter an invalid scope,
        # namely, inside `(...)`, self_stack should be locked.
        def lock
          @locked = true
        end

        def unlock
          @locked = false
        end

        def locked?
          @locked
        end

        def pop
          if !@locked
            @next_self = nil
            @stack.pop
          end
        end

        def last
          if @locked
            nil
          else
            @stack.last
          end
        end

        def empty?
          @stack.none?
        end

        private

        def push_self(next_self)
          @stack << next_self
        end
      end
    end
  end
end
