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

        Schema.define(**kargs)
      end

      NullResolveType = ->(obj, ctx) {
        raise(NotImplementedError, "This schema was loaded from string, so it can't resolve types for objects")
      }

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
            fail NotImplementedError, "#{kind} not implemented"
          end
        end

        def define_type(type, type_resolver)
          case type.fetch("kind")
          when "ENUM"
            EnumType.define(
              name: type["name"],
              description: type["description"],
              values: type["enumValues"].map { |enum|
                EnumType::EnumValue.new(
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
            Field.define(
              name: type["name"],
              type: type_resolver.call(type["type"]),
              description: type["description"],
              arguments: Hash[type["args"].map { |arg|
                [arg["name"], define_type(arg.merge("kind" => "ARGUMENT"), type_resolver)]
              }]
            )
          when "ARGUMENT"
            Argument.define(
              name: type["name"],
              type: type_resolver.call(type["type"]),
              description: type["description"],
              default_value: type["defaultValue"] ? JSON.parse(type["defaultValue"], quirks_mode: true) : nil
            )
          when "SCALAR"
            case type.fetch("name")
            when "Int"
              INT_TYPE
            when "String"
              STRING_TYPE
            when "Float"
              FLOAT_TYPE
            when "Boolean"
              BOOLEAN_TYPE
            when "ID"
              ID_TYPE
            else
              ScalarType.define(
                name: type["name"],
                description: type["description"]
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
            fail NotImplementedError, "#{type["kind"]} not implemented"
          end
        end
      end
    end
  end
end
