# frozen_string_literal: true

module GraphQL
  module Introspection
    class SchemaType < Introspection::BaseObject
      graphql_name "__Schema"
      description "A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all "\
                  "available types and directives on the server, as well as the entry points for "\
                  "query, mutation, and subscription operations."

      field :types, [GraphQL::Schema::LateBoundType.new("__Type")], "A list of all types supported by this server.", null: false, scope: false
      field :query_type, GraphQL::Schema::LateBoundType.new("__Type"), "The type that query operations will be rooted at.", null: false
      field :mutation_type, GraphQL::Schema::LateBoundType.new("__Type"), "If this server supports mutation, the type that mutation operations will be rooted at."
      field :subscription_type, GraphQL::Schema::LateBoundType.new("__Type"), "If this server support subscription, the type that subscription operations will be rooted at."
      field :directives, [GraphQL::Schema::LateBoundType.new("__Directive")], "A list of all directives supported by this server.", null: false, scope: false
      field :description, String, resolver_method: :schema_description

      def schema_description
        context.schema.description
      end

      def types
        types = context.warden.reachable_types + context.schema.extra_types
        types.sort_by!(&:graphql_name)
        types
      end

      def query_type
        permitted_root_type("query")
      end

      def mutation_type
        permitted_root_type("mutation")
      end

      def subscription_type
        permitted_root_type("subscription")
      end

      def directives
        @context.warden.directives
      end

      private

      def permitted_root_type(op_type)
        @context.warden.root_type_for_operation(op_type)
      end
    end
  end
end
