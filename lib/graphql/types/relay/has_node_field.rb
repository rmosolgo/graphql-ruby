# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module HasNodeField
        def self.included(child_class)
          add_node_field(child_class, id_type: GraphQL::Types::ID)
        end

        def self.[](id_type:)
          Module.new do
            define_singleton_method(:included) do |child_class|
              GraphQL::Types::Relay::HasNodeField.add_node_field(child_class, id_type: id_type)
            end
          end
        end

        def self.add_node_field(child_class, id_type:)
          child_class.field(
            name: "node",
            type: GraphQL::Types::Relay::Node,
            null: true,
            description: "Fetches an object given its ID.",
            relay_node_field: true
          ) do
            argument :id, id_type, description: "ID of the object."

            def resolve(_obj, args, ctx)
              ctx.schema.object_from_id(args[:id], ctx)
            end

            def resolve_field(obj, args, ctx)
              resolve(obj, args, ctx)
            end
          end
        end
      end
    end
  end
end
