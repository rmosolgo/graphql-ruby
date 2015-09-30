module GraphQL
  # Used to convert your {GraphQL::Schema} to a GraphQL schema string
  #
  # @example print your schema to standard output
  #   Schema = GraphQL::Schema.new(query: QueryType)
  #   puts GraphQL::Schema::Printer.print_schema(Schema)
  #
  module Schema::Printer
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
      case type
      when ScalarType
        print_scalar(type)
      when ObjectType
        print_object(type)
      when InterfaceType
        print_interface(type)
      when UnionType
        print_union(type)
      when EnumType
        print_enum(type)
      when InputObjectType
        print_input_object(type)
      else
        raise NotImplementedError, "Unexpected type #{type.class}"
      end
    end

    def print_scalar(type)
      "scalar #{type.name}"
    end

    def print_object(type)
      implementations = " implements #{type.interfaces.map(&:to_s).join(", ")}" unless type.interfaces.empty?
      "type #{type.name}#{implementations} {\n#{print_fields(type)}\n}"
    end

    def print_interface(type)
      "interface #{type.name} {\n#{print_fields(type)}\n}"
    end

    def print_union(type)
      "union #{type.name} = #{type.possible_types.map(&:to_s).join(" | ")}\n}"
    end

    def print_enum(type)
      values = type.values.values.map{ |v| "  #{v.name}" }.join("\n")
      "enum #{type.name} {\n#{values}\n}"
    end

    def print_input_object(type)
      fields = type.input_fields.values.map{ |field| "  #{print_input_value(field)}" }.join("\n")
      "input #{type.name} {\n#{fields}\n}"
    end

    def print_fields(type)
      type.fields.values.map{ |field| "  #{field.name}#{print_args(field)}: #{field.type}" }.join("\n")
    end

    def print_args(field)
      return if field.arguments.empty?
      "(#{field.arguments.values.map{ |arg| print_input_value(arg) }.join(", ")})"
    end

    def print_input_value(arg)
      default_string = " = #{print_value(arg.default_value, arg.type)}" unless arg.default_value.nil?
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
end
