# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object
    # @api private
    module BuildType
      module_function

      # @param schema [GraphQL::Schema]
      # @param graphql_obj_class [GraphQL::Object]
      # @return [GraphQL::ObjectType]
      def build_object_type(schema, graphql_obj_class)
        obj_type = GraphQL::ObjectType.define do
          name(graphql_obj_class.graphql_type_name)
          description(graphql_obj_class.description)
          interfaces(graphql_obj_class.interfaces)
          graphql_obj_class.fields.each do |field_inst|
            field_defn = field_inst.to_graphql(schema: schema)
            # Based on the return type of the field, determine whether
            # we should wrap it with connection helpers or not.
            field_defn_method = if field_defn.type.unwrap.name =~ /Connection\Z/
              :connection
            else
              :field
            end
            field_name = field_defn.name
            public_send(field_defn_method, field_name, field: field_defn)
          end

          obj_type.metadata[:object_class] = graphql_obj_class
        end
      end

      def parse_type(schema, type_expr, null:)
        list_type = false
        if type_expr.is_a?(Array)
          list_type = true
          type_expr = type_expr.first
        end

        type_name = to_type_name(type_expr)
        return_type = case type_name
        when "String"
          GraphQL::STRING_TYPE
        when "Int"
          GraphQL::INT_TYPE
        when "Float"
          GraphQL::FLOAT_TYPE
        when "Boolean"
          GraphQL::BOOLEAN_TYPE
        when "ID"
          GraphQL::BOOLEAN_TYPE
        when /\A\[.*\]\Z/
          list_type = true
          parse_type(schema, type_name[1..-2], null: true)
        when /.*!\Z/
          null = false
          parse_type(schema, type_name[1..-2], null: true)
        else
          schema.find_type(type_name)
        end

        # TODO This isn't going to handle circular dependencies
        if return_type.is_a?(Class) && return_type < GraphQL::Object
          return_type = return_type.to_graphql(schema: schema)
        end

        if !null
          return_type = return_type.to_non_null_type
        end

        if list_type
          return_type = return_type.to_list_type
        end

        return_type
      end

      def to_type_name(something)
        case something
        when Array
          to_type_name(something.first)
        when Module
          something.name
        when String
          something
        else
          raise "Unhandled to_type_name input: #{something} (#{something.class})"
        end
      end
    end
  end
end
