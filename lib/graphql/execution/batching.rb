# frozen_string_literal: true
require "graphql/execution/batching/authorize_step"
require "graphql/execution/batching/field_compatibility"
require "graphql/execution/batching/field_resolve_step"
require "graphql/execution/batching/runner"
require "graphql/execution/batching/selections_step"
module GraphQL
  module Execution
    module Batching
      def self.run(schema:, query_string: nil, document: nil, context: {}, validate: true, variables: {}, root_object: nil)
        document ||= GraphQL.parse(query_string)
        if validate
          validation_errors = schema.validate(document, context: context)
          if !validation_errors.empty?
            return {
              "errors" => validation_errors.map(&:to_h)
            }
          end
        end

        runner = Runner.new(schema, document, context, variables, root_object)
        runner.execute
      end
    end
  end
end
