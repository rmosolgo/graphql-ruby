# frozen_string_literal: true

require 'active_support/inflector'

module GraphQL
  class Schema
    module ReduceTypes
      # @param types [Array<GraphQL::BaseType>] members of a schema to crawl for all member types
      # @param camelize Boolean if the type reduce should camelize field and argument names
      # @return [GraphQL::Schema::TypeMap] `{name => Type}` pairs derived from `types`
      def self.reduce(types, renamer: nil)
        renamer ||= DefaultRenamer

        type_map = GraphQL::Schema::TypeMap.new
        types.each do |type|
          reduce_type(type, type_map, type.name, renamer)
        end
        type_map
      end

      private

      attr_reader :types, :camelize

      # Based on `type`, add members to `type_hash`.
      # If `type` has already been visited, just return the `type_hash` as-is
      def self.reduce_type(type, type_hash, context_description, renamer)
        if !type.is_a?(GraphQL::BaseType)
          message = "#{context_description} has an invalid type: must be an instance of GraphQL::BaseType, not #{type.class.inspect} (#{type.inspect})"
          raise GraphQL::Schema::InvalidTypeError.new(message)
        end

        type = type.unwrap

        # Don't re-visit a type
        if !type_hash.fetch(type.name, nil).equal?(type)
          validate_type(type, context_description)
          type_hash[type.name] = type
          crawl_type(type, type_hash, context_description, renamer)
        end
      end

      def self.crawl_type(type, type_hash, context_description, renamer)
        if type.kind.fields?
          type.fields.keys.each do |name|
            original_field = type.fields.delete(name)
            field = renamer.rename_field(original_field)

            reduce_type(field.type, type_hash, "Field #{type.name}.#{field.name}", renamer)

            field.arguments.keys.each do |argument_name|
              original_argument = field.arguments.delete(argument_name)
              argument = renamer.rename_argument(original_argument)

              reduce_type(argument.type, type_hash, "Argument #{name} on #{type.name}.#{field.name}", renamer)
              field.arguments[argument.name] = argument
            end

            type.fields[field.name] = field
          end
        end
        if type.kind.object?
          type.interfaces.each do |interface|
            reduce_type(interface, type_hash, "Interface on #{type.name}", renamer)
          end
        end
        if type.kind.union?
          type.possible_types.each do |possible_type|
            reduce_type(possible_type, type_hash, "Possible type for #{type.name}", renamer)
          end
        end
        if type.kind.input_object?
          type.arguments.keys.each do |argument_name|
            original_argument = type.arguments.delete(argument_name)
            argument = renamer.rename_argument(original_argument)

            reduce_type(argument.type, type_hash, "Input field #{type.name}.#{argument_name}", renamer)
            type.arguments[argument.name] = argument
          end
        end
      end

      def self.validate_type(type, context_description)
        error_message = GraphQL::Schema::Validation.validate(type)
        if error_message
          raise GraphQL::Schema::InvalidTypeError.new("#{context_description} is invalid: #{error_message}")
        end
      end
    end
  end
end
