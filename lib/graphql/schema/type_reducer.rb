# frozen_string_literal: true

require 'active_support/inflector'

module GraphQL
  class Schema
    class TypeReducer
      # @param types [Array<GraphQL::BaseType>] members of a schema to crawl for all member types
      # @param camelize Boolean if the type reduce should camelize field and argument names
      def initialize(types, camelize: false)
        @types = types
        @camelize = camelize
      end

      # @return [GraphQL::Schema::TypeMap] `{name => Type}` pairs derived from `types`
      def reduce
        type_map = GraphQL::Schema::TypeMap.new
        types.each do |type|
          reduce_type(type, type_map, type.name)
        end
        type_map
      end

      private

      attr_reader :types, :camelize

      # Based on `type`, add members to `type_hash`.
      # If `type` has already been visited, just return the `type_hash` as-is
      def reduce_type(type, type_hash, context_description)
        if !type.is_a?(GraphQL::BaseType)
          message = "#{context_description} has an invalid type: must be an instance of GraphQL::BaseType, not #{type.class.inspect} (#{type.inspect})"
          raise GraphQL::Schema::InvalidTypeError.new(message)
        end

        type = type.unwrap

        # Don't re-visit a type
        if !type_hash.fetch(type.name, nil).equal?(type)
          validate_type(type, context_description)
          type_hash[type.name] = type
          crawl_type(type, type_hash, context_description)
        end
      end

      def crawl_type(type, type_hash, context_description)
        if type.kind.fields?
          type.fields.keys.each do |name|
            field = type.fields.delete(name)
            field = camelize_field(field) if camelize

            reduce_type(field.type, type_hash, "Field #{type.name}.#{field.name}")

            field.arguments.keys.each do |argument_name|
              argument = field.arguments.delete(argument_name)
              argument = camelize_argument(argument) if camelize

              reduce_type(argument.type, type_hash, "Argument #{name} on #{type.name}.#{field.name}")
              field.arguments[argument.name] = argument
            end

            type.fields[field.name] = field
          end
        end
        if type.kind.object?
          type.interfaces.each do |interface|
            reduce_type(interface, type_hash, "Interface on #{type.name}")
          end
        end
        if type.kind.union?
          type.possible_types.each do |possible_type|
            reduce_type(possible_type, type_hash, "Possible type for #{type.name}")
          end
        end
        if type.kind.input_object?
          type.arguments.keys.each do |argument_name|
            argument = type.arguments.delete(argument_name)
            argument = camelize_argument(argument) if camelize

            reduce_type(argument.type, type_hash, "Input field #{type.name}.#{argument_name}")
            type.arguments[argument.name] = argument
          end
        end
      end

      def validate_type(type, context_description)
        error_message = GraphQL::Schema::Validation.validate(type)
        if error_message
          raise GraphQL::Schema::InvalidTypeError.new("#{context_description} is invalid: #{error_message}")
        end
      end

      def camelize_argument(argument)
        defined_as = argument.name
        camelized = ActiveSupport::Inflector.camelize(defined_as, false)

        if argument.as
          argument.redefine(name: camelized)
        else
          argument.redefine(name: camelized, as: defined_as)
        end
      end

      def camelize_field(field)
        defined_as = field.name
        camelized = ActiveSupport::Inflector.camelize(defined_as, false)

        if field.resolve_proc.is_a?(GraphQL::Field::Resolve::NameResolve)
          field.redefine(name: camelized, property: defined_as.to_sym)
        else
          field.redefine(name: camelized)
        end
      end
    end
  end
end
