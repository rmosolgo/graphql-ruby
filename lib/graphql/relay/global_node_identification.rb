require 'singleton'
module GraphQL
  module Relay
    # This object provides helpers for working with global IDs.
    # It's assumed you'll only have 1!
    # GlobalIdField depends on that, since it calls class methods
    # which delegate to the singleton instance.
    class GlobalNodeIdentification
      class << self
        attr_accessor :id_separator
      end
      self.id_separator = "-"

      include GraphQL::DefinitionHelpers::DefinedByConfig
      defined_by_config :object_from_id_proc, :type_from_object_proc
      attr_accessor :object_from_id_proc, :type_from_object_proc

      class << self
        attr_accessor :instance
        def new(*args, &block)
          @instance = super
        end

        def from_global_id(id)
          instance.from_global_id(id)
        end

        def to_global_id(type_name, id)
          instance.to_global_id(type_name, id)
        end
      end

      # Returns `NodeInterface`, which all Relay types must implement
      def interface
        @interface ||= begin
          ident = self
          GraphQL::InterfaceType.define do
            name "Node"
            field :id, !types.ID
            resolve_type -> (obj) {
              ident.type_from_object(obj)
            }
          end
        end
      end

      # Returns a field for finding objects from a global ID, which Relay needs
      def field
        ident = self
        GraphQL::Field.define do
          type(ident.interface)
          argument :id, !types.ID
          resolve -> (obj, args, ctx) {
            ident.object_from_id(args[:id], ctx)
          }
        end
      end

      # Create a global ID for type-name & ID
      # (This is an opaque transform)
      def to_global_id(type_name, id)
        id_str = id.to_s
        if type_name.include?(self.class.id_separator) || id_str.include?(self.class.id_separator)
          raise "to_global_id(#{type_name}, #{id}) contains reserved characters `#{self.class.id_separator}`"
        end
        Base64.strict_encode64([type_name, id_str].join(self.class.id_separator))
      end

      # Get type-name & ID from global ID
      # (This reverts the opaque transform)
      def from_global_id(global_id)
        Base64.decode64(global_id).split(self.class.id_separator)
      end

      # Use the provided config to
      # get a type for a given object
      def type_from_object(object)
        type_result = @type_from_object_proc.call(object)
        if !type_result.is_a?(GraphQL::BaseType)
          type_str = "#{type_result} (#{type_result.class.name})"
          raise "type_from_object(#{object}) returned #{type_str}, but it should return a GraphQL type"
        else
          type_result
        end
      end

      # Use the provided config to
      # get an object from a UUID
      def object_from_id(id, ctx)
        @object_from_id_proc.call(id, ctx)
      end
    end
  end
end
