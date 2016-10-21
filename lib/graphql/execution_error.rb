module GraphQL
  # If a field's resolve function returns a {ExecutionError},
  # the error will be inserted into the response's `"errors"` key
  # and the field will resolve to `nil`.
  class ExecutionError < GraphQL::Error
    # @return [GraphQL::Language::Nodes::Field] the field where the error occured
    attr_accessor :ast_node

    # @return [String] an array describing the JSON-path into the execution
    # response which corresponds to this error.
    attr_accessor :path

    ### Ruby 1.9.3 unofficial support
    # def initialize(message, ast_node: nil)
    def initialize(message, options = {})
      ast_node = options.fetch(:ast_node, nil)

      @ast_node = ast_node
      super(message)
    end

    # @return [Hash] An entry for the response's "errors" key
    def to_h
      hash = {
        "message" => message,
      }
      if ast_node
        hash["locations"] = [
          {
            "line" => ast_node.line,
            "column" => ast_node.col,
          }
        ]
      end
      if path
        hash["path"] = path
      end
      hash
    end
  end
end
