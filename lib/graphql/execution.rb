# frozen_string_literal: true
require "graphql/execution/directive_checks"
require "graphql/execution/next"
require "graphql/execution/interpreter"
require "graphql/execution/lazy"
require "graphql/execution/lookahead"
require "graphql/execution/multiplex"
require "graphql/execution/errors"

module GraphQL
  module Execution
    # @api private
    class Skip < GraphQL::RuntimeError
      attr_accessor :path
      def ast_nodes=(_ignored); end

      def finalize_graphql_result(query, result_data, key)
        case result_data
        when Hash
          result_data.delete(key)
        when Array
          result_data.delete_at(key)
        else
          raise "Unexpected result data #{result_data.class}: #{result_data}"
        end
      end
    end
  end
end
