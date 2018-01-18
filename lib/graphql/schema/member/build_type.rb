# frozen_string_literal: true
module GraphQL
  class Schema
    class Member
      # @api private
      module BuildType
        module_function
        # @param type_expr [String, Class, GraphQL::BaseType]
        # @return [GraphQL::BaseType]
        def parse_type(type_expr, null:)
          list_type = false

          return_type = case type_expr
          when String
            case type_expr
            when "String"
              GraphQL::STRING_TYPE
            when "Int", "Integer"
              GraphQL::INT_TYPE
            when "Float"
              GraphQL::FLOAT_TYPE
            when "Boolean"
              GraphQL::BOOLEAN_TYPE
            when "ID"
              GraphQL::ID_TYPE
            when /\A\[.*\]\Z/
              list_type = true
              # List members are required by default
              parse_type(type_expr[1..-2], null: false)
            when /.*!\Z/
              null = false
              parse_type(type_expr[0..-2], null: true)
            else
              maybe_type = Object.const_get(type_expr)
              case maybe_type
              when GraphQL::BaseType
                maybe_type
              when Class
                if maybe_type < GraphQL::Schema::Member
                  maybe_type.graphql_definition
                else
                  raise "Unexpected class found for GraphQL type: #{type_expr} (must be GraphQL::Object)"
                end
              end
            end
          when GraphQL::BaseType, GraphQL::Schema::LateBoundType
            type_expr
          when Array
            case type_expr.length
            when 1
              list_type = true
              # List members are required by default
              parse_type(type_expr.first, null: false)
            when 2
              inner_type, nullable_nil = type_expr
              if !nullable_nil.nil?
                raise "Use an array of [T] or [T, nil] for list types; other arrays are not supported"
              end
              list_type = true
              parse_type(type_expr.first, null: true)
            else
              raise "Use an array of [T] or [T, nil] for list types; other arrays are not supported"
            end
          when Class
            if Class < GraphQL::Schema::Member
              type_expr.graphql_definition
            else
              # Eg `String` => GraphQL::STRING_TYPE
              parse_type(type_expr.name, null: true)
            end
          end

          # Apply list_type first, that way the
          # .to_non_null_type applies to the list type, not the inner type
          if list_type
            return_type = return_type.to_list_type
          end

          if !null
            return_type = return_type.to_non_null_type
          end


          return_type
        end

        def to_type_name(something)
          case something
          when GraphQL::BaseType, GraphQL::Schema::LateBoundType
            something.unwrap.name
          when Array
            to_type_name(something.first)
          when Module
            if something < GraphQL::Schema::Member
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

        def camelize(string)
          return string unless string.include?("_")
          camelized = string.split('_').map(&:capitalize).join
          camelized[0] = camelized[0].downcase
          if string.start_with?("__")
            camelized = "__#{camelized}"
          end
          camelized
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
end
