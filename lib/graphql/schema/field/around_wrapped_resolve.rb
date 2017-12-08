# frozen_string_literal: true

module GraphQL
  class Schema
    class Field
      class AroundWrappedResolve
        def initialize(inner_resolve:, around_resolve_methods:)
          @inner_resolve = inner_resolve
          @around_resolve_methods = around_resolve_methods
        end

        def call(obj, args, ctx)
          invoke_around_method(obj, args, 0) {
            @inner_resolve.call(obj, args, ctx)
          }
        end

        private

        def invoke_around_method(obj, args, idx)
          method_name = @around_resolve_methods[idx]
          if method_name
            if args.any?
              obj.public_send(method_name, **args.to_kwargs) {
                invoke_around_method(obj, args, idx + 1) { yield }
              }
            else
              obj.public_send(method_name) {
                invoke_around_method(obj, args, idx + 1) { yield }
              }
            end
          else
            yield
          end
        end
      end
    end
  end
end
