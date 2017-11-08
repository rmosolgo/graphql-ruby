# frozen_string_literal: true
module GraphQL
  # The base class for things that make up the schema,
  # eg objects, enums, scalars.
  #
  # @api private
  class SchemaMember
    # Adds a layer of caching over user-supplied `.to_graphql` methods.
    # Users override `.to_graphql`, but all runtime code should use `.graphql_definition`.
    module CachedGraphQLDefinition
      # A cached result of {.to_graphql}.
      # It's cached here so that user-overridden {.to_graphql} implementations
      # are also cached
      def graphql_definition
        @graphql_definition ||= to_graphql
      end
    end

    class << self
      include CachedGraphQLDefinition

      # Delegate to the derived type definition if possible.
      # This is tricky because missing methods cause the definition to be built & cached.
      def method_missing(method_name, *args, &block)
        if graphql_definition.respond_to?(method_name)
          graphql_definition.public_send(method_name, *args, &block)
        else
          super
        end
      end

      # Check if the derived type definition responds to the method
      # @return [Boolean]
      def respond_to_missing?(method_name, incl_private = false)
        graphql_definition.respond_to?(method_name, incl_private) || super
      end

      # Call this with a new name to override the default name for this schema member; OR
      # call it without an argument to get the name of this schema member
      # @param new_name [String]
      # @return [String]
      def graphql_name(new_name = nil)
        if new_name
          @graphql_name = new_name
        else
          @graphql_name || self.name.split("::").last
        end
      end

      # Call this method to provide a new description; OR
      # call it without an argument to get the description
      # @param new_description [String]
      # @return [String]
      def description(new_description = nil)
        if new_description
          @description = new_description
        else
          @description || (superclass <= GraphQL::SchemaMember ? superclass.description : nil)
        end
      end

      def to_graphql
        raise NotImplementedError
      end

      def to_list_type
        ListTypeProxy.new(self)
      end

      def to_non_null_type
        NonNullTypeProxy.new(self)
      end
    end
  end
end

require 'graphql/schema_member/list_type_proxy'
require 'graphql/schema_member/non_null_type_proxy'
require 'graphql/schema_member/has_fields'