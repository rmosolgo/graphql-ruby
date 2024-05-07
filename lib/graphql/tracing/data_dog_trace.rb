# frozen_string_literal: true

module GraphQL
  module Tracing
    module DataDogTrace
      # @param tracer [#trace] Deprecated
      # @param analytics_enabled [Boolean] Deprecated
      # @param analytics_sample_rate [Float] Deprecated
      def initialize(tracer: nil, analytics_enabled: false, analytics_sample_rate: 1.0, service: nil, **rest)
        if tracer.nil?
          tracer = defined?(Datadog::Tracing) ? Datadog::Tracing : Datadog.tracer
        end
        @tracer = tracer

        @analytics_enabled = analytics_enabled
        @analytics_sample_rate = analytics_sample_rate

        @service_name = service
        @has_prepare_span = respond_to?(:prepare_span)
        super
      end

      def lex(query_string:)
        @tracer.trace('graphql.lex', resource: query_string, service: @service_name, type: 'graphql') do |span|
          if @has_prepare_span
            prepare_span('lex', {query_string: query_string}, span)
          end
          super
        end
      end

      def parse(query_string:)
        @tracer.trace('graphql.parse', resource: query_string, service: @service_name, type: 'graphql') do |span|
          span.set_tag('graphql.source', query_string)
          if @has_prepare_span
            prepare_span('parse', {query_string: query_string}, span)
          end
          super
        end
      end

      def validate(query:, validate:)
        @tracer.trace('graphql.validate', resource: query.selected_operation_name, service: @service_name, type: 'graphql') do |span|
          span.set_tag('graphql.source', query.query_string)
          if @has_prepare_span
            prepare_span('validate', {query: query, validate: validate}, span)
          end
          super
        end
      end
      
      def analyze_multiplex(multiplex:)
        operations = multiplex.queries.map(&:selected_operation_name).compact.join(', ')
        resource = if operations.empty?
          first_query = multiplex.queries.first
          fallback_transaction_name(first_query && first_query.context)
        else
          operations
        end
        @tracer.trace('graphql.analyze_multiplex', resource: resource, service: @service_name, type: 'graphql') do |span|
          if @has_prepare_span
            prepare_span('analyze_multiplex', {multiplex: multiplex}, span)
          end
          super
        end
      end

      def analyze_query(query:)
        @tracer.trace('graphql.analyze', resource: query.query_string, service: @service_name, type: 'graphql') do |span|
          if @has_prepare_span
            prepare_span('analyze_query', {query: query}, span)
          end
          super
        end
      end

      def execute_multiplex(multiplex:)
        operations = multiplex.queries.map(&:selected_operation_name).compact.join(', ')
        resource = if operations.empty?
          first_query = multiplex.queries.first
          fallback_transaction_name(first_query && first_query.context)
        else
          operations
        end
        @tracer.trace('graphql.execute_multiplex', resource: resource, service: @service_name, type: 'graphql') do |span|
          span.set_tag('graphql.source', "Multiplex[#{multiplex.queries.map(&:query_string).join(', ')}]")
          if @has_prepare_span
            prepare_span("execute_multiplex", {multiplex: multiplex}, span)
          end
          super
        end
      end

      def execute_query(query:)
        @tracer.trace('graphql.execute', resource: query.selected_operation_name, service: @service_name, type: 'graphql') do |span|
          span.set_tag('graphql.source', query.query_string)
          span.set_tag('graphql.operation.type', query.selected_operation.operation_type)
          span.set_tag('graphql.operation.name', query.selected_operation_name) if query.selected_operation_name
          query.provided_variables.each do |key, value|
            span.set_tag("graphql.variables.#{key}", value)
          end
          if @has_prepare_span
            prepare_span('execute_query', {query: query}, span)
          end
          super
        end
      end

      def execute_query_lazy(query:, multiplex:)
        resource = if query
          query.selected_operation_name || fallback_transaction_name(query.context)
        else
          operations = multiplex && multiplex.queries.map(&:selected_operation_name).compact.join(', ')
          if operations.nil?
            nil
          elsif operations.empty?
            first_query = multiplex.queries.first
            fallback_transaction_name(first_query && first_query.context)
          else
            operations
          end
        end
        @tracer.trace('graphql.execute_lazy', resource: resource, service: @service_name, type: 'graphql') do |span|
          if @has_prepare_span
            prepare_span('execute_lazy', {query: query, multiplex: multiplex}, span)
          end
          super
        end
      end

      def execute_field_span(span_key, query, field, ast_node, arguments, object)
        return_type = field.type.unwrap
        trace_field = if return_type.kind.scalar? || return_type.kind.enum?
          (field.trace.nil? && @trace_scalars) || field.trace
        else
          true
        end
        platform_key = if trace_field
          @platform_key_cache[DataDogTrace].platform_field_key_cache[field]
        else
          nil
        end
        if platform_key && trace_field
          @tracer.trace("graphql.#{span_key}", resource: platform_key, service: @service_name, type: 'graphql') do |span|
            query.provided_variables.each do |key, value|
              span.set_tag("graphql.variables.#{key}", value)
            end

            if @has_prepare_span
              prepare_span_data = { query: query, field: field, ast_node: ast_node, arguments: arguments, object: object }
              prepare_span(span_key, prepare_span_data, span)
            end
            yield
          end
        else
          yield
        end
      end

      def execute_field(query:, field:, ast_node:, arguments:, object:)
        execute_field_span('resolve', query, field, ast_node, arguments, object) do
          super(query: query, field: field, ast_node: ast_node, arguments: arguments, object: object)
        end
      end

      def execute_field_lazy(query:, field:, ast_node:, arguments:, object:)
        execute_field_span('resolve_lazy', query, field, ast_node, arguments, object) do
          super(query: query, field: field, ast_node: ast_node, arguments: arguments, object: object)
        end
      end

      def authorized_span(span_key, object, type, query)
        platform_key = @platform_key_cache[DataDogTrace].platform_authorized_key_cache[type]
        @tracer.trace("graphql.#{span_key}", resource: platform_key, service: @service_name, type: 'graphql') do |span|
          if @has_prepare_span
            prepare_span(span_key, {object: object, type: type, query: query}, span)
          end
          yield
        end
      end

      def authorized(query:, type:, object:)
        authorized_span('authorized', object, type, query) do
          super(query: query, type: type, object: object)
        end
      end

      def authorized_lazy(object:, type:, query:)
        authorized_span('authorized_lazy', object, type, query) do
          super(query: query, type: type, object: object)
        end
      end

      def resolve_type_span(span_key, object, type, query)
        platform_key = @platform_key_cache[DataDogTrace].platform_resolve_type_key_cache[type]
        @tracer.trace("graphql.#{span_key}", resource: platform_key, service: @service_name, type: 'graphql') do |span|
          if @has_prepare_span
            prepare_span(span_key, {object: object, type: type, query: query}, span)
          end
          yield
        end
      end

      def resolve_type(object:, type:, query:)
        resolve_type_span('resolve_type', object, type, query) do
          super(object: object, query: query, type: type)
        end
      end

      def resolve_type_lazy(object:, type:, query:)
        resolve_type_span('resolve_type_lazy', object, type, query) do
          super(object: object, query: query, type: type)
        end
      end

      include PlatformTrace

      # Implement this method in a subclass to apply custom tags to datadog spans
      # @param key [String] The event being traced
      # @param data [Hash] The runtime data for this event (@see GraphQL::Tracing for keys for each event)
      # @param span [Datadog::Tracing::SpanOperation] The datadog span for this event
      # def prepare_span(key, data, span)
      # end

      def platform_field_key(field)
        field.path
      end

      def platform_authorized_key(type)
        "#{type.graphql_name}.authorized"
      end

      def platform_resolve_type_key(type)
        "#{type.graphql_name}.resolve_type"
      end
    end
  end
end
