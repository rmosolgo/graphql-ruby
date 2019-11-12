# frozen_string_literal: true

require 'set'

module GraphQL
  module Introspection
    class SchemaType < Introspection::BaseObject
      graphql_name "__Schema"
      description "A GraphQL Schema defines the capabilities of a GraphQL server. It exposes all "\
                  "available types and directives on the server, as well as the entry points for "\
                  "query, mutation, and subscription operations."

      field :types, [GraphQL::Schema::LateBoundType.new("__Type")], "A list of all types supported by this server.", null: false
      field :queryType, GraphQL::Schema::LateBoundType.new("__Type"), "The type that query operations will be rooted at.", null: false
      field :mutationType, GraphQL::Schema::LateBoundType.new("__Type"), "If this server supports mutation, the type that mutation operations will be rooted at.", null: true
      field :subscriptionType, GraphQL::Schema::LateBoundType.new("__Type"), "If this server support subscription, the type that subscription operations will be rooted at.", null: true
      field :directives, [GraphQL::Schema::LateBoundType.new("__Directive")], "A list of all directives supported by this server.", null: false

      def types
        types = reachable_types
        if context.interpreter?
          types.map { |t| t.metadata[:type_class] || raise("Invariant: can't introspect non-class-based type: #{t}") }
        else
          types
        end
      end

      def query_type
        @query_type ||= permitted_root_type("query")
      end

      def mutation_type
        @mutation_type ||= permitted_root_type("mutation")
      end

      def subscription_type
        @subscription_type ||= permitted_root_type("subscription")
      end

      def directives
        context.schema.directives.values
      end

      private

      def permitted_root_type(op_type)
        context.warden.root_type_for_operation(op_type)
      end

      def reachable_types
        reachable_types = Set.new

        unvisited_types = []
        unvisited_types << query_type if query_type
        unvisited_types << mutation_type if mutation_type
        unvisited_types << subscription_type if subscription_type
        unvisited_types.concat(context.schema.introspection_system.object_types)
        context.schema.orphan_types.each do |orphan_type|
          unvisited_types << orphan_type.graphql_definition if context.warden.get_type(orphan_type.graphql_name)
        end

        until unvisited_types.empty?
          type = unvisited_types.pop
          if reachable_types.add?(type)
            if type.is_a?(GraphQL::InputObjectType) || type.is_a?(GraphQL::Directive)
              # recurse into visible arguments
              context.warden.arguments(type).each do |argument|
                argument_type = argument.type.unwrap
                unvisited_types << argument_type
              end
            elsif type.is_a?(GraphQL::UnionType)
              # recurse into visible possible types
              context.warden.possible_types(type).each do |possible_type|
                unvisited_types << possible_type
              end
            else
              if type.is_a?(GraphQL::InterfaceType)
                # recurse into visible orphan types
                type.orphan_types.each do |orphan_type|
                  unvisited_types << orphan_type.graphql_definition if context.warden.get_type(orphan_type.graphql_name)
                end
              elsif type.is_a?(GraphQL::ObjectType)
                # recurse into visible implemented interfaces
                context.warden.interfaces(type).each do |interface|
                  unvisited_types << interface
                end
              end

              # recurse into visible fields
              context.warden.fields(type).each do |field|
                field_type = field.type.unwrap
                unvisited_types << field_type
                # recurse into visible arguments
                context.warden.arguments(field).each do |argument|
                  argument_type = argument.type.unwrap
                  unvisited_types << argument_type
                end
              end
            end
          end
        end

        reachable_types.sort_by(&:graphql_name)
      end
    end
  end
end
