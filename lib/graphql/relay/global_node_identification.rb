require 'singleton'
module GraphQL
  module Relay
    # This object provides helpers for working with global IDs.
    # It's assumed you'll only have 1!
    #
    # GlobalIdField depends on that, since it calls class methods
    # which delegate to the singleton instance.
    #
    class GlobalNodeIdentification
      include GraphQL::Define::InstanceDefinable
      accepts_definitions(:object_from_id, :type_from_object, :to_global_id, :from_global_id)

      class << self
        attr_accessor :instance, :id_separator
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

      self.id_separator = "-"

      def initialize
        @to_global_id_proc = DEFAULT_TO_GLOBAL_ID
        @from_global_id_proc = DEFAULT_FROM_GLOBAL_ID
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

      DEFAULT_TO_GLOBAL_ID = -> (type_name, id) {
        id_str = id.to_s
        if type_name.include?(self.id_separator) || id_str.include?(self.id_separator)
          raise "to_global_id(#{type_name}, #{id}) contains reserved characters `#{self.id_separator}`"
        end
        Base64.strict_encode64([type_name, id_str].join(self.id_separator))
      }

      DEFAULT_FROM_GLOBAL_ID = -> (global_id) {
        Base64.decode64(global_id).split(self.id_separator)
      }

      # Create a global ID for type-name & ID
      # (This is an opaque transform)
      def to_global_id(type_name, id)
        @to_global_id_proc.call(type_name, id)
      end

      def to_global_id=(proc)
        @to_global_id_proc = proc
      end

      # Get type-name & ID from global ID
      # (This reverts the opaque transform)
      def from_global_id(global_id)
        @from_global_id_proc.call(global_id)
      end

      def from_global_id=(proc)
        @from_global_id_proc = proc
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

      def type_from_object=(proc)
        @type_from_object_proc = proc
      end

      # Use the provided config to
      # get an object from a UUID
      def object_from_id(id, ctx)
        @object_from_id_proc.call(id, ctx)
      end

      def object_from_id=(proc)
        @object_from_id_proc = proc
      end
    end
  end
end
