# frozen_string_literal: true
module GraphQL
  class Query
    class VariableValidationError < GraphQL::ExecutionError
      attr_accessor :value, :validation_result

      def initialize(variable_ast, type, value, validation_result, msg: nil)
        @value = value
        @validation_result = validation_result

        msg ||= "Variable $#{variable_ast.name} of type #{type.to_type_signature} was provided invalid value"

        if !problem_fields.empty?
          msg += " for #{problem_fields.join(", ")}"
        end

        super(msg)
        self.ast_node = variable_ast
      end

      def to_h
        # It is possible there are other extension items in this error, so handle
        # a one level deep merge explicitly. However beyond that only show the
        # latest value and problems.
        super.merge({ "extensions" => { "value" => value_for_extensions, "problems" => validation_result.problems }}) do |key, oldValue, newValue|
          if oldValue.respond_to?(:merge)
            oldValue.merge(newValue)
          else
            newValue
          end
        end
      end

      private

      def value_for_extensions(value = @value)
        case value
        when Array
          value.map { |item| value_for_extensions(item) }
        when Hash
          value.each_with_object({}) do |(key, item), result|
            result[key] = value_for_extensions(item)
          end
        when Float
          value.finite? ? value : value.to_s
        else
          value
        end
      end

      def problem_fields
        @problem_fields ||= @validation_result
          .problems
          .reject { |problem| problem["path"].empty? }
          .map { |problem| "#{problem['path'].join('.')} (#{problem['explanation']})" }
      end
    end
  end
end
