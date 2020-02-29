# frozen_string_literal: true

module GraphQL
  class Schema
    class Member
      # Adds a layer of caching over user-supplied `.to_graphql` methods.
      # Users override `.to_graphql`, but all runtime code should use `.graphql_definition`.
      # @api private
      # @see concrete classes that extend this, eg {Schema::Object}
      module CachedGraphQLDefinition
        # A cached result of {.to_graphql}.
        # It's cached here so that user-overridden {.to_graphql} implementations
        # are also cached
        def graphql_definition
          @graphql_definition ||= to_graphql
        end

        # This is for a common interface with .define-based types
        def type_class
          self
        end

        # Wipe out the cached graphql_definition so that `.to_graphql` will be called again.
        def initialize_copy(original)
          super
          @graphql_definition = nil
        end
      end
    end
  end
end
