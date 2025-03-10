# frozen_string_literal: true

require "graphql/tracing/notifications_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby times to Sentry.
    #
    # @example Installing the tracer
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::SentryTrace
    #   end
    # @see NotificationsTrace Configuration Options in the parent module
    module SentryTrace
      include NotificationsTrace

      class SentryEngine < NotificationsTrace::Engine
        def instrument(keyword, payload)
          return yield unless Sentry.initialized?

          platform_key = name_for(keyword, payload)

          Sentry.with_child_span(op: platform_key, start_timestamp: Sentry.utc_now.to_f) do |span|
            result = yield
            return result unless span

            span.finish
            if keyword == :execute
              queries = payload.queries
              operation_names = queries.map{|q| operation_name(q) }
              span.set_description(operation_names.join(", "))

              if queries.size == 1
                query = queries.first
                set_this_txn_name = query.context[:set_sentry_transaction_name]
                if set_this_txn_name == true || (set_this_txn_name.nil? && @set_transaction_name)
                  Sentry.configure_scope do |scope|
                    scope.set_transaction_name(transaction_name(query))
                  end
                end
                span.set_data('graphql.document', query.query_string)
                if query.selected_operation_name
                  span.set_data('graphql.operation.name', query.selected_operation_name)
                end
                span.set_data('graphql.operation.type', query.selected_operation.operation_type)
              end
            end

            result
          end
        end

        PARSE_NAME = "graphql.parse"
        LEX_NAME = "graphql.lex"
        VALIDATE_NAME = "graphql.validate"
        EXECUTE_NAME = "graphql.execute"
        ANALYZE_NAME = "graphql.analyze"

        private

        def operation_name(query)
          selected_op = query.selected_operation
          if selected_op
            [selected_op.operation_type, selected_op.name].compact.join(' ')
          else
            'GraphQL Operation'
          end
        end

        def platform_field_key(field)
          "graphql.field.#{field.path}"
        end

        def platform_authorized_key(type)
          "graphql.authorized.#{type.graphql_name}"
        end

        def platform_resolve_type_key(type)
          "graphql.resolve_type.#{type.graphql_name}"
        end

        def platform_source_class_key(source_class)
          "graphql.source.#{source_class.name.gsub("::", ".")}"
        end

        class Event < NotificationsTrace::Engine::Event
          def start
            if Sentry.initialized?
              @span = Sentry.get_current_scope.get_span
              span_name = @engine.name_for(@keyword, @payload)
              @span.start_child(op: span_name)
            end
          end

          def finish
            @span&.finish
          end
        end
      end

      def initialize(engine: SentryEngine, **rest)
        super
      end
    end
  end
end
