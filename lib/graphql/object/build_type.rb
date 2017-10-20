# frozen_string_literal: true
# test_via: ../object.rb

module GraphQL
  class Object < GraphQL::SchemaMember
    # @api private
    module BuildType
      module_function

      # @param schema [GraphQL::Schema]
      # @param graphql_obj_class [GraphQL::Object]
      # @return [GraphQL::ObjectType]
      def build_object_type(graphql_obj_class)
        obj_type = GraphQL::ObjectType.define do
          name(graphql_obj_class.graphql_name)
          description(graphql_obj_class.description)
          interfaces(graphql_obj_class.interfaces)
          graphql_obj_class.fields.each do |field_inst|
            field_defn = field_inst.to_graphql
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

      # @param type_expr
      # @return [GraphQL::BaseType]
      def parse_type(type_expr, null:)
        list_type = false

        return_type = case type_expr
        when String
          case type_expr
          when "String"
            GraphQL::STRING_TYPE
          when "Int"
            GraphQL::INT_TYPE
          when "Float"
            GraphQL::FLOAT_TYPE
          when "Boolean"
            GraphQL::BOOLEAN_TYPE
          when "ID"
            GraphQL::ID_TYPE
          when /\A\[.*\]\Z/
            list_type = true
            parse_type(type_expr[1..-2], null: true)
          when /.*!\Z/
            null = false
            parse_type(type_expr[1..-2], null: true)
          else
            maybe_type = Object.const_get(type_expr)
            case maybe_type
            when GraphQL::BaseType
              maybe_type
            when Class
              if maybe_type < GraphQL::SchemaMember
                maybe_type.to_graphql
              else
                raise "Unexpected class found for GraphQL type: #{type_expr} (must be GraphQL::Object)"
              end
            end
          end
        when GraphQL::BaseType
          type_expr
        when Array
          if type_expr.length != 1
            raise "Use an array of length = 1 for list types; other arrays are not supported"
          end
          list_type = true
          parse_type(type_expr.first, null: true)
        when Class
          if Class < GraphQL::Object
            type_expr.to_graphql
          else
            # Eg `String` => GraphQL::STRING_TYPE
            parse_type(type_expr.name, null: true)
          end
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
        when GraphQL::BaseType
          something.name
        when Array
          to_type_name(something.first)
        when Module
          if something < GraphQL::SchemaMember
            something.graphql_name
          else
            something.name.split("::").last
          end
        when String
          something.gsub(/\]\[\!/, "").split("::").last
        else
          raise "Unhandled to_type_name input: #{something} (#{something.class})"
        end
      end

      def underscore(string)
        string
          .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2') # URLDecoder -> URL_Decoder
          .gsub(/([a-z\d])([A-Z])/,'\1_\2')     # someThing -> some_Thing
          .downcase
      end
    end
  end
end
