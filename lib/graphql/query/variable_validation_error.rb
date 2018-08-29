# frozen_string_literal: true
module GraphQL
  class Query
    class VariableValidationError < GraphQL::ExecutionError
      attr_accessor :value, :validation_result

      def initialize(variable_ast, type, value, validation_result)
        @value = value
        @validation_result = validation_result

        msg = "Variable #{variable_ast.name} of type #{type} was provided invalid value"

        # Note: by merging the extensions we introduce the possibility that
        # if two extensions contain the same key then the last one in the
        # array will be the value chosen.
        extensions = validation_result.extensions ? validation_result.extensions.inject(&:merge) : nil
        super(msg, extensions: extensions)
        self.ast_node = variable_ast
      end

      def to_h
        super.merge({ "value" => value, "problems" => validation_result.problems })
      end
    end
  end
end
