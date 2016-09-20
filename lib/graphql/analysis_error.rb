module GraphQL
  class AnalysisError < GraphQL::ExecutionError
    def initialize(message, ast_node: nil)
      err = super(message)
      err.ast_node = ast_node
      err
    end
  end
end
