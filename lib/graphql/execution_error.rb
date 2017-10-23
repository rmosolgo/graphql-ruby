# frozen_string_literal: true
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

    # @return [Hash] Optional data for error objects
    attr_accessor :options

    def initialize(message, ast_node: nil, options: nil)
      @ast_node = ast_node
      @options = options
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
      if options
        hash.merge!(options)
      end
      hash
    end
  end
end
