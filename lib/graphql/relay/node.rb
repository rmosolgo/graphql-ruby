require 'singleton'
require 'base64'
module GraphQL
  module Relay
    # To get a `NodeField` and `NodeInterface`,
    # define an object that responds to:
    #   - object_from_id
    #   - type_from_object
    # and pass it to `Node.create`
    #
    class Node
      include Singleton

      # Allows you to call methods on the class
      def self.method_missing(method_name, *args, &block)
        if instance.respond_to?(method_name)
          instance.send(method_name, *args, &block)
        else
          super
        end
      end

      # Return interface and field using implementation
      def create(implementation)
        interface = create_interface(implementation)
        field = create_field(implementation, interface)
        [interface, field]
      end

      # Create a global ID for type-name & ID
      # (This is an opaque transform)
      def to_global_id(type_name, id)
        Base64.strict_encode64("#{type_name}-#{id}")
      end

      # Get type-name & ID from global ID
      # (This reverts the opaque transform)
      def from_global_id(global_id)
        Base64.decode64(global_id).split("-")
      end

      private

      def create_interface(implementation)
        GraphQL::InterfaceType.define do
          name "Node"
          field :id, !types.ID
          resolve_type -> (obj) {
            implementation.type_from_object(obj)
          }
        end
      end

      def create_field(implementation, interface)
        GraphQL::Field.define do
          type(interface)
          argument :id, !types.ID
          resolve -> (obj, args, ctx) {
            implementation.object_from_id(args[:id])
          }
        end
      end
    end
  end
end
