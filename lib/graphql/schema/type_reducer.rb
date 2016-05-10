module GraphQL
  class Schema
    # Starting from a given type, discover other types in the system by
    # traversing that type's fields, possible_types, etc
    class TypeReducer
      attr_reader :type, :existing_type_hash, :name

      def initialize(type, existing_type_hash, name = nil)
        @name = name
        if type.respond_to?(:name) && existing_type_hash.fetch(type.name, nil).equal?(type)
          @result = existing_type_hash
        else
          @type = type
        end
        @existing_type_hash = existing_type_hash
      end

      def result
        @result ||= find_types(type, existing_type_hash)
      end

      # Reduce all of `types` and return the combined result
      def self.find_all(types)
        type_map = GraphQL::Schema::TypeMap.new
        types.reduce(type_map) do |memo, type|
          self.new(type, memo, type.name).result
        end
      end

      private

      def find_types(type, type_hash)
        validate_type(type, name)
        type_hash[type.name] = type
        if type.kind.fields?
          type.all_fields.each do |field|
            reduce_type(field.type, type_hash, "Field #{type.name}.#{field.name}")
            field.arguments.each do |name, argument|
              reduce_type(argument.type, type_hash, "Argument #{name} on #{type.name}.#{field.name}")
            end
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
          type.input_fields.each do |name, input_field|
            reduce_type(input_field.type, type_hash, "Input field #{type.name}.#{name}")
          end
        end

        type_hash
      end

      def reduce_type(type, type_hash, name)
        if type.is_a?(GraphQL::BaseType)
          inner_type = type.unwrap
          self.class.new(inner_type, type_hash, name).result
        else
          message = "#{name} has an invalid type: must be an instance of GraphQL::BaseType, not #{type.class.inspect} (#{type.inspect})"
          raise GraphQL::Schema::InvalidTypeError.new(message)
        end
      end

      def validate_type(type, name)
        error_message = GraphQL::Schema::Validation.validate(type)
        if error_message
          raise GraphQL::Schema::InvalidTypeError.new("#{name} is invalid: #{error_message}")
        end
      end
    end
  end
end
