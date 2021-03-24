# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module ConnectionBehaviors
        extend Forwardable
        def_delegators :@object, :cursor_from_node, :parent

        def self.included(child_class)
          child_class.extend(ClassMethods)
          child_class.extend(Relay::DefaultRelay)
          child_class.default_relay(true)
          child_class.has_nodes_field(true)
          child_class.node_nullable(true)
          child_class.edges_nullable(true)
          child_class.edge_nullable(true)
          add_page_info_field(child_class)
        end

        module ClassMethods
          # @return [Class]
          attr_reader :node_type

          # @return [Class]
          attr_reader :edge_class

          # Configure this connection to return `edges` and `nodes` based on `edge_type_class`.
          #
          # This method will use the inputs to create:
          # - `edges` field
          # - `nodes` field
          # - description
          #
          # It's called when you subclass this base connection, trying to use the
          # class name to set defaults. You can call it again in the class definition
          # to override the default (or provide a value, if the default lookup failed).
          def edge_type(edge_type_class, edge_class: GraphQL::Relay::Edge, node_type: edge_type_class.node_type, nodes_field: self.has_nodes_field, node_nullable: self.node_nullable, edges_nullable: self.edges_nullable, edge_nullable: self.edge_nullable)
            # Set this connection's graphql name
            node_type_name = node_type.graphql_name

            @node_type = node_type
            @edge_type = edge_type_class
            @edge_class = edge_class

            field :edges, [edge_type_class, null: edge_nullable],
              null: edges_nullable,
              description: "A list of edges.",
              legacy_edge_class: edge_class, # This is used by the old runtime only, for EdgesInstrumentation
              connection: false

            define_nodes_field(node_nullable) if nodes_field

            description("The connection type for #{node_type_name}.")
          end

          # Filter this list according to the way its node type would scope them
          def scope_items(items, context)
            node_type.scope_items(items, context)
          end

          # Add the shortcut `nodes` field to this connection and its subclasses
          def nodes_field(node_nullable: self.node_nullable)
            define_nodes_field(node_nullable)
          end

          def authorized?(obj, ctx)
            true # Let nodes be filtered out
          end

          def accessible?(ctx)
            node_type.accessible?(ctx)
          end

          def visible?(ctx)
            node_type.visible?(ctx)
          end

          # Set the default `node_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `node_nullable(false)` in your base class to make non-null `node` and `nodes` fields.
          def node_nullable(new_value = nil)
            if new_value.nil?
              defined?(@node_nullable) ? @node_nullable : superclass.node_nullable
            else
              @node_nullable = new_value
            end
          end

          # Set the default `edges_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `edges_nullable(false)` in your base class to make non-null `edges` fields.
          def edges_nullable(new_value = nil)
            if new_value.nil?
              defined?(@edges_nullable) ? @edges_nullable : superclass.edges_nullable
            else
              @edges_nullable = new_value
            end
          end

          # Set the default `edge_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `edge_nullable(false)` in your base class to make non-null `edge` fields.
          def edge_nullable(new_value = nil)
            if new_value.nil?
              defined?(@edge_nullable) ? @edge_nullable : superclass.edge_nullable
            else
              @edge_nullable = new_value
            end
          end

          # Set the default `nodes_field` for this class and its child classes. (Defaults to `true`.)
          # Use `nodes_field(false)` in your base class to prevent adding of a nodes field.
          def has_nodes_field(new_value = nil)
            if new_value.nil?
              defined?(@nodes_field) ? @nodes_field : superclass.has_nodes_field
            else
              @nodes_field = new_value
            end
          end

          private

          def define_nodes_field(nullable)
            field :nodes, [@node_type, null: nullable],
              null: nullable,
              description: "A list of nodes.",
              connection: false
          end
        end

        class << self
          def add_page_info_field(obj_type)
            obj_type.field :page_info, GraphQL::Types::Relay::PageInfo, null: false, description: "Information to aid in pagination."
          end
        end

        # By default this calls through to the ConnectionWrapper's edge nodes method,
        # but sometimes you need to override it to support the `nodes` field
        def nodes
          @object.edge_nodes
        end

        def edges
          if @object.is_a?(GraphQL::Pagination::Connection)
            @object.edges
          elsif context.interpreter?
            context.schema.after_lazy(object.edge_nodes) do |nodes|
              nodes.map { |n| self.class.edge_class.new(n, object) }
            end
          else
            # This is done by edges_instrumentation
            @object.edge_nodes
          end
        end
      end
    end
  end
end
