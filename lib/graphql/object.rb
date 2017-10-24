# frozen_string_literal: true
require "graphql/object/argument"
require "graphql/object/build_type"
require "graphql/object/field"
require "graphql/object/instrumentation"
require "graphql/object/resolvers"

module GraphQL
  class Object < GraphQL::SchemaMember
    attr_reader :object

    def initialize(object, context)
      @object = object
      @context = context
    end

    class << self
      def implements(*new_interfaces)
        new_interfaces.each do |int|
          if int.is_a?(Class) && int < GraphQL::Interface
            # Add the graphql field defns
            int.fields.each do |field|
              fields << field
            end
            # And call the implemented hook
            int.apply_implemented(self)
          end
        end
        interfaces.concat(new_interfaces)
      end

      # TODO inheritance?
      def interfaces
        @interfaces ||= []
      end

      # Define a field on this object
      def field(*args, &block)
        fields << GraphQL::Object::Field.new(*args, &block)
      end

      # Fields defined on this class
      # TODO should this inherit?
      def fields
        @fields ||= []
      end

      # TODO this caching will not work with rebooting
      # @return [GraphQL::ObjectType]
      def to_graphql
        @to_graphql ||= begin
          obj_type = GraphQL::ObjectType.new
          obj_type.name = graphql_name
          obj_type.description = description
          obj_type.interfaces = interfaces

          fields.each do |field_inst|
            field_defn = field_inst.to_graphql
            # TODO don't use Define APIs here
            # Based on the return type of the field, determine whether
            # we should wrap it with connection helpers or not.
            field_defn_fn = if field_defn.type.unwrap.name =~ /Connection\Z/
              GraphQL::Define::AssignConnection
            else
              GraphQL::Define::AssignObjectField
            end
            field_name = field_defn.name
            field_defn_fn.call(obj_type, field_name, field: field_defn)
          end

          obj_type.metadata[:object_class] = self

          obj_type
        end
      end
    end
  end
end
