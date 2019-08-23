# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Test whether `ast_value` is a valid input for `type`
    class LiteralValidator
      def initialize(context:)
        @context = context
        @warden = context.warden
      end

      def validate(ast_value, type)
        if type.nil?
          # this means we're an undefined argument, see #present_input_field_values_are_valid
          maybe_raise_if_invalid(ast_value) do
            false
          end
        elsif ast_value.is_a?(GraphQL::Language::Nodes::NullValue)
          maybe_raise_if_invalid(ast_value) do
            !type.kind.non_null?
          end
        elsif type.kind.non_null?
          maybe_raise_if_invalid(ast_value) do
            (!ast_value.nil?)
          end && validate(ast_value, type.of_type)
        elsif type.kind.list?
          item_type = type.of_type
          ensure_array(ast_value).all? { |val| validate(val, item_type) }
        elsif ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          true
        elsif type.kind.scalar? && constant_scalar?(ast_value)
          maybe_raise_if_invalid(ast_value) do
            type.valid_input?(ast_value, @context)
          end
        elsif type.kind.enum?
          maybe_raise_if_invalid(ast_value) do
            if ast_value.is_a?(GraphQL::Language::Nodes::Enum)
              type.valid_input?(ast_value.name, @context)
            else
              # if our ast_value isn't an Enum it's going to be invalid so return false
              false
            end
          end
        elsif type.kind.input_object? && ast_value.is_a?(GraphQL::Language::Nodes::InputObject)
          maybe_raise_if_invalid(ast_value) do
            required_input_fields_are_present(type, ast_value) && present_input_field_values_are_valid(type, ast_value)
          end
        else
          maybe_raise_if_invalid(ast_value) do
            false
          end
        end
      end

      private

      def maybe_raise_if_invalid(ast_value)
        ret = yield
        if !@context.schema.error_bubbling && !ret
          e = LiteralValidationError.new
          e.ast_value = ast_value
          raise e
        else
          ret
        end
      end

      # The GraphQL grammar supports variables embedded within scalars but graphql.js
      # doesn't support it so we won't either for simplicity
      def constant_scalar?(ast_value)
        if ast_value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
          false
        elsif ast_value.is_a?(Array)
          ast_value.all? { |element| constant_scalar?(element) }
        elsif ast_value.is_a?(GraphQL::Language::Nodes::InputObject)
          ast_value.arguments.all? { |arg| constant_scalar?(arg.value) }
        else
          true
        end
      end

      def required_input_fields_are_present(type, ast_node)
        # TODO - would be nice to use these to create an error message so the caller knows
        # that required fields are missing
        required_field_names = @warden.arguments(type)
          .select { |f| f.type.kind.non_null? }
          .map(&:name)
        present_field_names = ast_node.arguments.map(&:name)
        missing_required_field_names = required_field_names - present_field_names
        if @context.schema.error_bubbling
          missing_required_field_names.empty?
        else
          missing_required_field_names.all? do |name|
            validate(GraphQL::Language::Nodes::NullValue.new(name: name), @warden.arguments(type).find { |f| f.name == name }.type )
          end
        end
      end

      def present_input_field_values_are_valid(type, ast_node)
        field_map = @warden.arguments(type).reduce({}) { |m, f| m[f.name] = f; m}
        ast_node.arguments.all? do |value|
          field = field_map[value.name]
          # we want to call validate on an argument even if it's an invalid one
          # so that our raise exception is on it instead of the entire InputObject
          type = field && field.type
          validate(value.value, type)
        end
      end

      def ensure_array(value)
        value.is_a?(Array) ? value : [value]
      end
    end
  end
end
