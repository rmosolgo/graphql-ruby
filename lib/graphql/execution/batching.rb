# frozen_string_literal: true
require "graphql/execution/batching/authorize_step"
require "graphql/execution/batching/field_compatibility"
require "graphql/execution/batching/field_resolve_step"
require "graphql/execution/batching/runner"
require "graphql/execution/batching/selections_step"
module GraphQL
  module Execution
    module Batching
      def self.run(schema:, query_string: nil, document: nil, context: {}, validate: true, variables: {}, root_object: nil, visibility_profile: nil)
        document ||= GraphQL.parse(query_string)
        query = GraphQL::Query.new(schema, document: document, validate: validate, context: context, variables: variables, root_value: root_object, visibility_profile: visibility_profile)
        if validate && !query.valid?
          return {
            "errors" => query.static_errors.map(&:to_h)
          }
        end
        runner = Runner.new(query)
        runner.execute
      end
    end
  end
end
