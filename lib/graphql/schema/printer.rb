module GraphQL
  class Schema
    # Used to convert your {GraphQL::Schema} to a GraphQL schema string
    #
    # @example print your schema to standard output
    #   Schema = GraphQL::Schema.new(query: QueryType)
    #   puts GraphQL::Schema::Printer.print_schema(Schema)
    #
    module Printer
      extend self

      # Return a GraphQL schema string for the defined types in the schema
      # @param schema [GraphQL::Schema]
      def print_schema(schema)
        print_filtered_schema(schema, method(:is_defined_type))
      end

      # Return the GraphQL schema string for the introspection type system
      def print_introspection_schema
        query_root = ObjectType.define do
          name "Query"
        end
        schema = Schema.new(query: query_root)
        print_filtered_schema(schema, method(:is_introspection_type))
      end

      private

      def print_filtered_schema(schema, type_filter)
        types = schema.types.values.select{ |type| type_filter.call(type) }.sort_by(&:name)
        types.map{ |type| print_type(type) }.join("\n\n")
      end

      BUILTIN_SCALARS = Set.new(["String", "Boolean", "Int", "Float", "ID"])
      private_constant :BUILTIN_SCALARS

      def is_introspection_type(type)
        type.name.start_with?("__")
      end

      def is_defined_type(type)
        !is_introspection_type(type) && !BUILTIN_SCALARS.include?(type.name)
      end

      def print_type(type)
        TypeKindPrinters::STRATEGIES.fetch(type.kind).print(type)
      end

      module TypeKindPrinters
        module FieldPrinter
          def print_fields(type)
            type.all_fields.map{ |field| "  #{field.name}#{print_args(field)}: #{field.type}" }.join("\n")
          end

          def print_args(field)
            return if field.arguments.empty?
            "(#{field.arguments.values.map{ |arg| print_input_value(arg) }.join(", ")})"
          end

          def print_input_value(arg)
            if arg.default_value.nil?
              default_string = nil
            else
              default_string = " = #{print_value(arg.default_value, arg.type)}"
            end

            "#{arg.name}: #{arg.type.to_s}#{default_string}"
          end

          def print_value(value, type)
            case type
            when FLOAT_TYPE
              value.to_f.inspect
            when INT_TYPE
              value.to_i.inspect
            when BOOLEAN_TYPE
              (!!value).inspect
            when ScalarType, ID_TYPE, STRING_TYPE
              value.to_s.inspect
            when EnumType
              value.to_s
            when InputObjectType
              fields = value.to_h.map{ |field_name, field_value|
                field_type = type.input_fields.fetch(field_name.to_s).type
                "#{field_name}: #{print_value(field_value, field_type)}"
              }.join(", ")
              "{ #{fields} }"
            when NonNullType
              print_value(value, type.of_type)
            when ListType
              "[#{value.to_a.map{ |v| print_value(v, type.of_type) }.join(", ")}]"
            else
              raise NotImplementedError, "Unexpected value type #{type.inspect}"
            end
          end
        end

        class ScalarPrinter
          def self.print(type)
            "scalar #{type.name}"
          end
        end

        class ObjectPrinter
          extend FieldPrinter
          def self.print(type)
            if type.interfaces.any?
              implementations = " implements #{type.interfaces.map(&:to_s).join(", ")}"
            else
              implementations = nil
            end
            "type #{type.name}#{implementations} {\n#{print_fields(type)}\n}"
          end
        end

        class InterfacePrinter
          extend FieldPrinter
          def self.print(type)
            "interface #{type.name} {\n#{print_fields(type)}\n}"
          end
        end

        class UnionPrinter
          def self.print(type)
            "union #{type.name} = #{type.possible_types.map(&:to_s).join(" | ")}\n}"
          end
        end

        class EnumPrinter
          def self.print(type)
            values = type.values.values.map{ |v| "  #{v.name}" }.join("\n")
            "enum #{type.name} {\n#{values}\n}"
          end
        end

        class InputObjectPrinter
          extend FieldPrinter
          def self.print(type)
            fields = type.input_fields.values.map{ |field| "  #{print_input_value(field)}" }.join("\n")
            "input #{type.name} {\n#{fields}\n}"
          end
        end

        STRATEGIES = {
          GraphQL::TypeKinds::SCALAR =>       ScalarPrinter,
          GraphQL::TypeKinds::OBJECT =>       ObjectPrinter,
          GraphQL::TypeKinds::INTERFACE =>    InterfacePrinter,
          GraphQL::TypeKinds::UNION =>        UnionPrinter,
          GraphQL::TypeKinds::ENUM =>         EnumPrinter,
          GraphQL::TypeKinds::INPUT_OBJECT => InputObjectPrinter,
        }
      end
      private_constant :TypeKindPrinters
    end
  end
end
