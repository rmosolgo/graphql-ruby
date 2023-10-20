# frozen_string_literal: true

module GraphQL
  module Tracing
    module PrometheusTrace
      include PlatformTrace

      def initialize(client: PrometheusExporter::Client.default, keys_whitelist: ["execute_field", "execute_field_lazy"], collector_type: "graphql", **rest)
        @client = client
        @keys_whitelist = keys_whitelist
        @collector_type = collector_type

        super(**rest)
      end

      {
        'lex' => "graphql.lex",
        'parse' => "graphql.parse",
        'validate' => "graphql.validate",
        'analyze_query' => "graphql.analyze",
        'analyze_multiplex' => "graphql.analyze",
        'execute_multiplex' => "graphql.execute",
        'execute_query' => "graphql.execute",
        'execute_query_lazy' => "graphql.execute",
      }.each do |trace_method, platform_key|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**data, &block)
            instrument_execution("#{platform_key}", "#{trace_method}", &block)
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
        field.path
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end

      private

      def instrument_execution(platform_key, key, &block)
        if @keys_whitelist.include?(key)
          start = ::Process.clock_gettime ::Process::CLOCK_MONOTONIC
          result = block.call
          duration = ::Process.clock_gettime(::Process::CLOCK_MONOTONIC) - start
          @client.send_json(
            type: @collector_type,
            duration: duration,
            platform_key: platform_key,
            key: key
          )
          result
        else
          yield
        end
      end
    end
  end
end
