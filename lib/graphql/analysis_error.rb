module GraphQL
  class AnalysisError < GraphQL::ExecutionError
    def initialize(message, ast_node = nil)
      err = super(message)
      # resolves an issue in rbx
      unless err.nil?
        err.ast_node = ast_node
      end
      err
    end
  end
end
