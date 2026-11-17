# frozen_string_literal: true
#--
# typed: strict

module GraphQL
  module Execution
    class Interpreter
      class ExecutionErrors
        #: (GraphQL::Query::Context ctx, GraphQL::Language::Nodes::AbstractNode ast_node, Array[String | Integer] path) -> void
        def initialize(ctx, ast_node, path)
          @context = ctx #: GraphQL::Query::Context
          @ast_node = ast_node #: GraphQL::Language::Nodes::AbstractNode
          @path = path #: Array[String | Integer]
        end

        #: (Object err_or_msg) -> void
        def add(err_or_msg)
          err = case err_or_msg
          when String
            GraphQL::ExecutionError.new(err_or_msg)
          when GraphQL::ExecutionError
            err_or_msg
          else
            raise ArgumentError, "expected String or GraphQL::ExecutionError, not #{err_or_msg.class} (#{err_or_msg.inspect})"
          end
          err.ast_node ||= @ast_node
          err.path ||= @path
          @context.add_error(err)
        end
      end
    end
  end
end
