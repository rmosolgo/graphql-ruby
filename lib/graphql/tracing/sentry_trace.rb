# frozen_string_literal: true

module GraphQL
  module Tracing
    module SentryTrace
      include PlatformTrace

      {
        "lex" => "graphql.lex",
        "parse" => "graphql.parse",
        "validate" => "graphql.validate",
        "analyze_query" => "graphql.analyze",
        "analyze_multiplex" => "graphql.analyze",
        "execute_multiplex" => "graphql.execute",
        "execute_query" => "graphql.execute",
        "execute_query_lazy" => "graphql.execute",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
        def #{trace_method}(**data, &block)
          instrument_execution("#{platform_key}", "#{trace_method}", data, &block)
        end
        RUBY
      end

      def platform_execute_field(platform_key, &block)
        instrument_execution(platform_key, "execute_field", &block)
      end

      def platform_execute_field_lazy(platform_key, &block)
        instrument_execution(platform_key, "execute_field_lazy", &block)
      end

      def platform_authorized(platform_key, &block)
        instrument_execution(platform_key, "authorized", &block)
      end

      def platform_authorized_lazy(platform_key, &block)
        instrument_execution(platform_key, "authorized_lazy", &block)
      end

      def platform_resolve_type(platform_key, &block)
        instrument_execution(platform_key, "resolve_type", &block)
      end

      def platform_resolve_type_lazy(platform_key, &block)
        instrument_execution(platform_key, "resolve_type_lazy", &block)
      end

      def platform_field_key(field)
        "graphql.#{field.path}"
      end

      def platform_authorized_key(type)
        "graphql.authorized.#{type.graphql_name}"
      end

      def platform_resolve_type_key(type)
        "graphql.resolve_type.#{type.graphql_name}"
      end

      private

      def instrument_execution(op, trace_method, data=nil, &block)
        return yield unless Sentry.initialized?

        Sentry.with_child_span(op: op, start_timestamp: Sentry.utc_now.to_f) do |span|
          result = block.call
          span.finish

          if trace_method == "execute_query" && data
            span.set_data(:query_string, data[:query].query_string)
            span.set_data(:operation_name, data[:query].selected_operation_name)
            span.set_data(:operation_type, data[:query].selected_operation.operation_type)
          end

          result
        end
      end
    end
  end
end
