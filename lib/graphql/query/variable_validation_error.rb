# frozen_string_literal: true
module GraphQL
  class Query
    class VariableValidationError < GraphQL::ExecutionError
      attr_accessor :value, :validation_result

      def initialize(variable_ast, type, value, validation_result)
        @value = value
        @validation_result = validation_result

        problems = validation_result.problems.map do |p|
          path_str = p['path'].size > 0 ? " on path '#{p['path'].join(" > ")}'" : ""
          "#{p['explanation']}#{path_str}"
        end

        msg = "Variable #{variable_ast.name} of type #{type} was provided invalid value with problems: \n#{problems.join('\n')}"
        super(msg)
        self.ast_node = variable_ast
      end

      def to_h
        super.merge({ "value" => value, "problems" => validation_result.problems })
      end
    end
  end
end
