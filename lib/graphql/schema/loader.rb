# frozen_string_literal: true
module GraphQL
  class Schema
    # You can use the result of {GraphQL::Introspection::INTROSPECTION_QUERY}
    # to make a schema. This schema is missing some important details like
    # `resolve` functions, but it does include the full type system,
    # so you can use it to validate queries.
    module Loader
      extend self

      # Create schema with the result of an introspection query.
      # @param introspection_result [Hash] A response from {GraphQL::Introspection::INTROSPECTION_QUERY}
      # @return [GraphQL::Schema] the schema described by `input`
      # @deprecated Use {GraphQL::Schema.from_introspection} instead
      def load(introspection_result)
        schema = introspection_result.fetch("data").fetch("__schema")

        types = {}
        type_resolver = ->(type) { -> { resolve_type(types, type) } }

        schema.fetch("types").each do |type|
          next if type.fetch("name").start_with?("__")
          type_object = define_type(type, type_resolver)
          types[type_object.name] = type_object
        end

        kargs = { orphan_types: types.values, resolve_type: NullResolveType }
        [:query, :mutation, :subscription].each do |root|
          type = schema["#{root}Type"]
          kargs[root] = types.fetch(type.fetch("name")) if type
        end

        Schema.define(**kargs, raise_definition_error: true)
      end

      NullResolveType = ->(type, obj, ctx) {
        raise(GraphQL::RequiredImplementationMissingError, "This schema was loaded from string, so it can't resolve types for objects")
      }

      NullScalarCoerce = ->(val, _ctx) { val }

      class << self
        private

        def resolve_type(types, type)
          case kind = type.fetch("kind")
          when "ENUM", "INTERFACE", "INPUT_OBJECT", "OBJECT", "SCALAR", "UNION"
            types.fetch(type.fetch("name"))
          when "LIST"
            ListType.new(of_type: resolve_type(types, type.fetch("ofType")))
          when "NON_NULL"
            NonNullType.new(of_type: resolve_type(types, type.fetch("ofType")))
          else
            fail GraphQL::RequiredImplementationMissingError, "#{kind} not implemented"
          end
        end

        def extract_default_value(default_value_str, input_value_ast)
          case input_value_ast
          when String, Integer, Float, TrueClass, FalseClass
            input_value_ast
          when GraphQL::Language::Nodes::Enum
            input_value_ast.name
          when GraphQL::Language::Nodes::NullValue
            nil
          when GraphQL::Language::Nodes::InputObject
            input_value_ast.to_h
          when Array
            input_value_ast.map { |element| extract_default_value(default_value_str, element) }
          else
            raise(
              "Encountered unexpected type when loading default value. "\
                    "input_value_ast.class is #{input_value_ast.class} "\
                    "default_value is #{default_value_str}"
            )
          end
        end

        def define_type(type, type_resolver)
          case type.fetch("kind")
          when "ENUM"
            EnumType.define(
              name: type["name"],
              description: type["description"],
              values: type["enumValues"].map { |enum|
                EnumType::EnumValue.define(
                  name: enum["name"],
                  description: enum["description"],
                  deprecation_reason: enum["deprecationReason"],
                  value: enum["name"]
                )
              })
          when "INTERFACE"
            InterfaceType.define(
              name: type["name"],
              description: type["description"],
              fields: Hash[(type["fields"] || []).map { |field|
                [field["name"], define_type(field.merge("kind" => "FIELD"), type_resolver)]
              }]
            )
          when "INPUT_OBJECT"
            InputObjectType.define(
              name: type["name"],
              description: type["description"],
              arguments: Hash[type["inputFields"].map { |arg|
                [arg["name"], define_type(arg.merge("kind" => "ARGUMENT"), type_resolver)]
              }]
            )
          when "OBJECT"
            ObjectType.define(
              name: type["name"],
              description: type["description"],
              interfaces: (type["interfaces"] || []).map { |interface|
                type_resolver.call(interface)
              },
              fields: Hash[type["fields"].map { |field|
                [field["name"], define_type(field.merge("kind" => "FIELD"), type_resolver)]
              }]
            )
          when "FIELD"
            GraphQL::Field.define(
              name: type["name"],
              type: type_resolver.call(type["type"]),
              description: type["description"],
              arguments: Hash[type["args"].map { |arg|
                [arg["name"], define_type(arg.merge("kind" => "ARGUMENT"), type_resolver)]
              }]
            )
          when "ARGUMENT"
            kwargs = {}
            if type["defaultValue"]
              kwargs[:default_value] = begin
                default_value_str = type["defaultValue"]

                dummy_query_str = "query getStuff($var: InputObj = #{default_value_str}) { __typename }"

                # Returns a `GraphQL::Language::Nodes::Document`:
                dummy_query_ast = GraphQL.parse(dummy_query_str)

                # Reach into the AST for the default value:
                input_value_ast = dummy_query_ast.definitions.first.variables.first.default_value

                extract_default_value(default_value_str, input_value_ast)
              end
            end

            GraphQL::Argument.define(
              name: type["name"],
              type: type_resolver.call(type["type"]),
              description: type["description"],
              method_access: false,
              **kwargs
            )
          when "SCALAR"
            type_name = type.fetch("name")
            if GraphQL::Schema::BUILT_IN_TYPES[type_name]
              GraphQL::Schema::BUILT_IN_TYPES[type_name]
            else
              ScalarType.define(
                name: type["name"],
                description: type["description"],
                coerce: NullScalarCoerce,
              )
            end
          when "UNION"
            UnionType.define(
              name: type["name"],
              description: type["description"],
              possible_types: type["possibleTypes"].map { |possible_type|
                type_resolver.call(possible_type)
              }
            )
          else
            fail GraphQL::RequiredImplementationMissingError, "#{type["kind"]} not implemented"
          end
        end
      end
    end
  end
end
