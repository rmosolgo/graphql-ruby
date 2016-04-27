module GraphQL
  class Schema
    class FieldValidator
      def validate(field, errors)
        implementation = GraphQL::Schema::ImplementationValidator.new(field, as: "Field", errors: errors)
        implementation.must_respond_to(:name)
        implementation.must_respond_to(:type)
        implementation.must_respond_to(:description)
        implementation.must_respond_to(:arguments) do |arguments|
          validator = GraphQL::Schema::EachItemValidator.new(errors)
          validator.validate(arguments.keys, as: "#{field.name}.arguments keys", must_be: "Strings") { |k| k.is_a?(String) }
        end
        implementation.must_respond_to(:deprecation_reason)
      end
    end
  end
end
