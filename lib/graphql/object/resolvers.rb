# frozen_string_literal: true

module GraphQL
  class Object
    module Resolvers
      # Grab the Resolve strategy which was assigned at boot
      class Metadata
        def call(obj, args, ctx)
          field_defn = ctx.field
          resolve_strategy = field_defn.metadata[:resolve_strategy]
          resolve_strategy.call(obj, args, ctx)
        end
      end

      # This is assigned at build-time. It should be overridden during boot.
      class Pending
        ERROR_MESSAGE = "Can't resolve %{name} because its resolve strategy is still pending." +
          " To resolve this error, call `Schema#boot` before running any queries."

        def call(obj, args, ctx)
          field_defn = ctx.field
          owner_type = ctx.irep_node.owner_type
          raise NotImplementedError, ERROR_MESSAGE % { name: "#{owner_type.name}.#{field_defn.name}" }
        end
      end
    end
  end
end
