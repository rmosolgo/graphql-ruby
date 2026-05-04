# frozen_string_literal: true
require "graphql/execution/prepare_object_step"
require "graphql/execution/input_values"
require "graphql/execution/field_resolve_step"
require "graphql/execution/finalize"
require "graphql/execution/load_argument_step"
require "graphql/execution/runner"
require "graphql/execution/selections_step"
module GraphQL
  module Execution
    module Finalizer
      attr_accessor :path
      def finalize_graphql_result(query, result_data, result_key)
        raise RequiredImplementationMissingError
      end
    end

    module HaltExecution
    end

    module PostProcessor
      def after_resolve(field_results)
        raise RequiredImplementationMissingError, "#{self.class}#after_resolve should handle `field_results` and return a new value to use"
      end
    end

    module Next
      module SchemaExtension
        def execute_next(query_str = nil, query: nil, subscription_topic: nil, context: nil, document: nil, operation_name: nil, variables: nil, root_value: nil, validate: true, visibility_profile: nil)
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
            query: query || query_str,
            subscription_topic: subscription_topic,
            document: document,
            context: context,
            validate: validate,
            variables: variables,
            root_value: root_value,
            operation_name: operation_name,
            visibility_profile: visibility_profile,
          }
          m_results = multiplex_next([query_opts], context: multiplex_context, max_complexity: nil)
          m_results[0]
        end

        def multiplex_next(query_options, context: {}, max_complexity: self.max_complexity)
          Next.run_all(self, query_options, context: context, max_complexity: max_complexity)
        end
      end

      def self.use(schema, as_default: false)
        schema.extend(SchemaExtension)
        schema.default_execution_next(as_default)
      end

      def self.run_all(schema, query_options, context: {}, max_complexity: schema.max_complexity)
        queries = query_options.map do |opts|
          query = case opts
          when Hash
            schema.query_class.new(schema, nil, **opts)
          when GraphQL::Query, GraphQL::Query::Partial
            opts
          else
            raise "Expected Hash or GraphQL::Query, not #{opts.class} (#{opts.inspect})"
          end
          query.context[:__graphql_execute_next] = true
          query
        end
        multiplex = Execution::Multiplex.new(schema: schema, queries: queries, context: context, max_complexity: max_complexity)
        runner = Runner.new(multiplex)
        runner.execute
      end
    end
  end
end
