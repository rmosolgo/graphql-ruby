# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module HasNodesField
        def self.included(child_class)
          add_nodes_field(child_class, id_type: GraphQL::Types::ID)
        end

        def self.[](id_type:)
          Module.new do
            define_singleton_method(:included) do |child_class|
              GraphQL::Types::Relay::HasNodesField.add_nodes_field(child_class, id_type: id_type)
            end
          end
        end

        def self.add_nodes_field(child_class, id_type:)
          child_class.field(
            name: "nodes",
            type: [GraphQL::Types::Relay::Node, null: true],
            null: false,
            description: "Fetches a list of objects given a list of IDs.",
            relay_nodes_field: true
          ) do
            argument :ids, [id_type], required: true, description: "IDs of the objects."

            def resolve(_obj, args, ctx)
              args[:ids].map { |id| ctx.schema.object_from_id(id, ctx) }
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
