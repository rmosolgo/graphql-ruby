# frozen_string_literal: true

module GraphQL
  module Tracing
    class SkylightTracing < PlatformTracing
      self.platform_keys = {
        "lex" => "graphql.language",
        "parse" => "graphql.language",
        "validate" => "graphql.prepare",
        "analyze_query" => "graphql.prepare",
        "analyze_multiplex" => "graphql.prepare",
        "execute_multiplex" => "graphql.execute",
        "execute_query" => "graphql.execute",
        "execute_query_lazy" => "graphql.execute",
      }

      def platform_trace(platform_key, key, data)
        if (query = data[:query])
          title = query.selected_operation_name || "<anonymous>"
          category = platform_key
          # Assign the endpoint so that queries will be grouped
          current_instance = Skylight::Instrumenter.instance
          if current_instance
            endpoint = "GraphQL/#{query.operation_type}.#{title}"
            current_instance.current_trace.endpoint = endpoint
          end
        elsif key.start_with?("execute_field")
          title = platform_key
          category = key
        else
          title = key
          category = platform_key
        end

        Skylight.instrument(category: category, title: title) do
          yield
        end
      end

      def platform_field_key(type, field)
        "graphql.#{type.name}.#{field.name}"
      end
    end
  end
end
