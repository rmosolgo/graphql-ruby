# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module EdgeBehaviors
        def self.included(child_class)
          child_class.description("An edge in a connection.")
          child_class.field(:cursor, String, null: false, description: "A cursor for use in pagination.")
          child_class.extend(ClassMethods)
          child_class.node_nullable(true)
        end

        module ClassMethods
          # Get or set the Object type that this edge wraps.
          #
          # @param node_type [Class] A `Schema::Object` subclass
          # @param null [Boolean]
          def node_type(node_type = nil, null: self.node_nullable)
            if node_type
              @node_type = node_type
              # Add a default `node` field
              field :node, node_type, null: null, description: "The item at the end of the edge.", connection: false
            end
            @node_type
          end

          def authorized?(obj, ctx)
            true
          end

          def accessible?(ctx)
            node_type.accessible?(ctx)
          end

          def visible?(ctx)
            node_type.visible?(ctx)
          end

          # Set the default `node_nullable` for this class and its child classes. (Defaults to `true`.)
          # Use `node_nullable(false)` in your base class to make non-null `node` field.
          def node_nullable(new_value = nil)
            if new_value.nil?
              defined?(@node_nullable) ? @node_nullable : superclass.node_nullable
            else
              @node_nullable = new_value
            end
          end
        end
      end
    end
  end
end
