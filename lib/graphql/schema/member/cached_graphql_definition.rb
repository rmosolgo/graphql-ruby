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
        def graphql_definition(silence_deprecation_warning: false)
          @graphql_definition ||= begin
            unless silence_deprecation_warning
              message = "Legacy `.graphql_definition` objects are deprecated and will be removed in GraphQL-Ruby 2.0. Use a class-based definition instead."
              caller_message = "\n\nCalled on #{self.inspect} from:\n #{caller(1, 25).map { |l| "  #{l}" }.join("\n")}"
              GraphQL::Deprecation.warn(message + caller_message)
            end
            to_graphql
          end
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
