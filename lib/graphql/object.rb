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
      include GraphQL::SchemaMember::HasFields

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

      # @return [GraphQL::ObjectType]
      def to_graphql
        obj_type = GraphQL::ObjectType.new
        obj_type.name = graphql_name
        obj_type.description = description
        obj_type.interfaces = interfaces

        fields.each do |field_inst|
          field_defn = field_inst.graphql_definition
          obj_type.fields[field_defn.name] = field_defn
        end

        obj_type.metadata[:object_class] = self

        obj_type
      end
    end
  end
end
