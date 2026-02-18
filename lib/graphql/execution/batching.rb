# frozen_string_literal: true
require "graphql/execution/batching/prepare_object_step"
require "graphql/execution/batching/field_compatibility"
require "graphql/execution/batching/field_resolve_step"
require "graphql/execution/batching/runner"
require "graphql/execution/batching/selections_step"
module GraphQL
  module Execution
    module Batching
      module SchemaExtension
        def execute_batching(query_str = nil, context: nil, document: nil, variables: nil, root_value: nil, validate: true, visibility_profile: nil)
          GraphQL::Execution::Batching.run(
            schema: self,
            query_string: query_str,
            document: document,
            context: context,
            validate: validate,
            variables: variables,
            root_object: root_value,
            visibility_profile: visibility_profile,
          )
        end
      end

      def self.use(schema)
        schema.extend(SchemaExtension)
      end

      def self.run(schema:, query_string: nil, document: nil, context: {}, validate: true, variables: {}, root_object: nil, visibility_profile: nil)
        query = GraphQL::Query.new(schema, query_string, document: document, validate: validate, context: context, variables: variables, root_value: root_object, visibility_profile: visibility_profile)
        runner = Runner.new(query)
        runner.execute
      end
    end
  end
end
