# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  module Types
    module Relay
      # Include this module to your root Query type to get a Relay-compliant `node(id: ID!): Node` field that uses the schema's `object_from_id` hook.
      #--
      # @requires_ancestor: GraphQL::Schema::Object
      module HasNodeField
        #: (singleton(GraphQL::Schema::Object) child_class) -> void
        def self.included(child_class)
          child_class.field(**field_options, &field_block)
          child_class.extend(ExecutionMethods)
        end

        module ExecutionMethods
          #: (GraphQL::Query::Context context, id: String) -> untyped
          def get_relay_node(context, id:)
            context.schema.object_from_id(id, context)
          end
        end

        #: (id: String) -> untyped
        def get_relay_node(id:)
          query_class = self.class #: as GraphQL::Types::Relay::HasNodeField::ExecutionMethods
          query_class.get_relay_node(context, id: id)
        end

        class << self
          #: -> Hash[Symbol, untyped]
          def field_options
            {
              name: "node",
              type: GraphQL::Types::Relay::Node,
              null: true,
              description: "Fetches an object given its ID.",
              relay_node_field: true,
              resolver_method: :get_relay_node,
              resolve_static: :get_relay_node,
            }
          end

          #: -> untyped
          def field_block
            Proc.new {
              #: self as GraphQL::Schema::Field
              argument :id, "ID!",
                description: "ID of the object."
            }
          end
        end
      end
    end
  end
end
