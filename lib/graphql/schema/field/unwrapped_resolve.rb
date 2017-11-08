# frozen_string_literal: true
module GraphQL
  class Schema
    class Field
      # This object is backed by an `Object`, but the resolve isn't expecting
      # that wrapper, so unwrap it before calling the inner resolver
      class UnwrappedResolve
        def initialize(inner_resolve:)
          @inner_resolve = inner_resolve
        end

        def call(obj, args, ctx)
          # Might be nil, still want to call the func in that case
          inner_obj = obj && obj.object
          @inner_resolve.call(inner_obj, args, ctx)
        end
      end
    end
  end
end
