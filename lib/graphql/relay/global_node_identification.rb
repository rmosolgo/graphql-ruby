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
      accepts_definitions(:object_from_id, :type_from_object, :to_global_id, :from_global_id, :description)
      lazy_defined_attr_accessor :description

      # Memoize the schema to support deprecated node_ident-level resolve functions
      # TODO: remove after Schema.resolve_type is required
      attr_accessor :schema

      class << self
        attr_accessor :id_separator
      end

      self.id_separator = "-"

      def initialize
        @to_global_id_proc = DEFAULT_TO_GLOBAL_ID
        @from_global_id_proc = DEFAULT_FROM_GLOBAL_ID
      end

      # Returns `NodeInterface`, which all Relay types must implement
      def interface
        @interface ||= begin
          ensure_defined
          ident = self
          if @type_from_object_proc
            # TODO: remove after Schema.resolve_type is required
            GraphQL::InterfaceType.define do
              name "Node"
              field :id, !types.ID
              resolve_type -> (obj, ctx) {
                ident.type_from_object(obj)
              }
            end
          else
            GraphQL::InterfaceType.define do
              name "Node"
              field :id, !types.ID
            end
          end
        end
      end

      # Returns a field for finding objects from a global ID, which Relay needs
      def field
        ensure_defined
        ident = self
        GraphQL::Field.define do
          type(ident.interface)
          argument :id, !types.ID
          resolve -> (obj, args, ctx) {
            ctx.query.schema.node_identification.object_from_id(args[:id], ctx)
          }
          description ident.description
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
        ensure_defined
        @to_global_id_proc.call(type_name, id)
      end

      def to_global_id=(proc)
        ensure_defined
        @to_global_id_proc = proc
      end

      # Get type-name & ID from global ID
      # (This reverts the opaque transform)
      def from_global_id(global_id)
        ensure_defined
        @from_global_id_proc.call(global_id)
      end

      def from_global_id=(proc)
        ensure_defined
        @from_global_id_proc = proc
      end

      # Use the provided config to
      # get a type for a given object
      # TODO: remove after Schema.resolve_type is required
      def type_from_object(object)
        ensure_defined
        warn("type_from_object(object) is deprecated; use Schema.resolve_type(object) instead")

        if @type_from_object_proc
          schema.resolve_type = @type_from_object_proc
          @type_from_object_proc = nil
        end

        schema.resolve_type(object)
      end

      def type_from_object=(new_type_from_object_proc)
        ensure_defined
        warn("type_from_object(object) is deprecated; use Schema.resolve_type(object) instead")
        @type_from_object_proc = new_type_from_object_proc
      end

      # Use the provided config to
      # get an object from a UUID
      def object_from_id(id, ctx)
        ensure_defined
        @object_from_id_proc.call(id, ctx)
      end

      def object_from_id=(proc)
        ensure_defined
        @object_from_id_proc = proc
      end
    end
  end
end
