# frozen_string_literal: true
module GraphQL
  # If a field's resolve function returns a {ExecutionError},
  # the error will be inserted into the response's `"errors"` key
  # and the field will resolve to `nil`.
  class ExecutionError < GraphQL::RuntimeError
    # @return [GraphQL::Language::Nodes::Field] the field where the error occurred
    def ast_node
      ast_nodes.first
    end

    def ast_node=(new_node)
      @ast_nodes = [new_node]
    end

    attr_accessor :ast_nodes

    # @return [String] an array describing the JSON-path into the execution
    # response which corresponds to this error.
    attr_accessor :path

    # @return [Hash] Optional data for error objects
    # @deprecated Use `extensions` instead of `options`. The GraphQL spec
    # recommends that any custom entries in an error be under the
    # `extensions` key.
    attr_accessor :options

    # @return [Hash] Optional custom data for error objects which will be added
    # under the `extensions` key.
    attr_accessor :extensions

    def initialize(message, ast_node: nil, ast_nodes: nil, options: nil, extensions: nil)
      @ast_nodes = ast_nodes || [ast_node]
      @options = options
      @extensions = extensions
      super(message)
    end

    # @return [Hash] An entry for the response's "errors" key
    def to_h
      hash = {
        "message" => message,
      }
      if ast_node
        hash["locations"] = @ast_nodes.map { |a| { "line" => a.line, "column" => a.col } }
      end
      if path
        hash["path"] = path
      end
      if options
        hash.merge!(options)
      end
      if extensions
        hash["extensions"] = extensions.each_with_object({}) { |(key, value), ext|
          ext[key.to_s] = value
        }
      end
      hash
    end
  end
end
