module GraphQL
  class Schema
    module Loader
      extend self

      def load(obj)
        schema = obj.fetch("data").fetch("__schema")

        types = {}
        type_resolver = -> (type) { -> { resolve_type(types, type) } }

        schema.fetch("types").each do |type|
          next if type.fetch("name").start_with?("__")
          type_object = define_type(type, type_resolver)
          types[type_object.name] = type_object
        end

        query = types.fetch(schema.fetch("queryType").fetch("name"))

        Schema.new(query: query, types: types.values)
      end

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
                value: enum["value"]
              )
            })
        when "INTERFACE"
          InterfaceType.define(
            name: type["name"],
            description: type["description"],
            fields: Hash[type["fields"].map { |field|
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
            default_value: type["defaultValue"]
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
