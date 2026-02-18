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
          multiplex_context = if context
            {
              backtrace: context[:backtrace],
              tracers: context[:tracers],
              trace: context[:trace],
              dataloader: context[:dataloader],
              trace_mode: context[:trace_mode],
            }
          else
            {}
          end
          query_opts = {
            query: query_str,
            document: document,
            context: context,
            validate: validate,
            variables: variables,
            root_value: root_value,
            visibility_profile: visibility_profile,
          }
          m_results = multiplex_batching([query_opts], context: multiplex_context, max_complexity: nil)
          m_results[0]
        end

        def multiplex_batching(query_options, context: {}, max_complexity: self.max_complexity)
          Batching.run_all(self, query_options, context: context, max_complexity: max_complexity)
        end
      end

      def self.use(schema)
        schema.extend(SchemaExtension)
      end

      def self.run_all(schema, query_options, context: {}, max_complexity: schema.max_complexity)
        queries = query_options.map do |opts|
          case opts
          when Hash
            schema.query_class.new(schema, nil, **opts)
          when GraphQL::Query, GraphQL::Query::Partial
            opts
          else
            raise "Expected Hash or GraphQL::Query, not #{opts.class} (#{opts.inspect})"
          end
        end
        multiplex = Execution::Multiplex.new(schema: schema, queries: queries, context: context, max_complexity: max_complexity)
        runner = Runner.new(multiplex)
        runner.execute
      end
    end
  end
end
