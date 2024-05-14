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

      def trace_helper(trace_key, resource, super_proc, **kwargs)
        @tracer.trace("graphql.#{trace_key}", resource: resource, service: @service_name, type: 'graphql') do |span|
          yield(span) if block_given?
          if @has_prepare_span
            prepare_span(trace_key, kwargs, span)
          end
          # caller method's super
          super_proc.call
        end
      end

      def lex(query_string:)
        trace_helper('lex', query_string, proc { super }, query_string: query_string)
      end

      def parse(query_string:)
        trace_helper('parse', query_string, proc { super }, query_string: query_string) do |span|
          span.set_tag('graphql.source', query_string)
        end
      end

      def validate(query:, validate:)
        trace_helper('validate', query.selected_operation_name, proc { super }, query: query, validate: validate) do |span|
          span.set_tag('graphql.source', query.query_string)
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
        trace_helper('analyze_multiplex', resource, proc { super }, multiplex: multiplex)
      end

      def analyze_query(query:)
        trace_helper('analyze', query.query_string, proc { super }, query: query)
      end

      def execute_multiplex(multiplex:)
        operations = multiplex.queries.map(&:selected_operation_name).compact.join(', ')
        resource = if operations.empty?
          first_query = multiplex.queries.first
          fallback_transaction_name(first_query && first_query.context)
        else
          operations
        end
        trace_helper('execute_multiplex', resource, proc { super }, multiplex: multiplex) do |span|
          span.set_tag('graphql.source', "Multiplex[#{multiplex.queries.map(&:query_string).join(', ')}]")
        end
      end

      def execute_query(query:)
        trace_helper('execute', query.selected_operation_name, proc { super }, query: query) do |span|
          span.set_tag('graphql.source', query.query_string)
          span.set_tag('graphql.operation.type', query.selected_operation.operation_type)
          span.set_tag('graphql.operation.name', query.selected_operation_name) if query.selected_operation_name
          query.provided_variables.each do |key, value|
            span.set_tag("graphql.variables.#{key}", value)
          end
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
        trace_helper('execute_lazy', resource, proc { super }, query: query, multiplex: multiplex)
      end

      def execute_field_span(span_key, super_proc, **kwargs)
        return_type = kwargs[:field].type.unwrap
        trace_field = if return_type.kind.scalar? || return_type.kind.enum?
          (kwargs[:field].trace.nil? && @trace_scalars) || kwargs[:field].trace
        else
          true
        end
        platform_key = if trace_field
          @platform_key_cache[DataDogTrace].platform_field_key_cache[kwargs[:field]]
        else
          nil
        end
        if platform_key && trace_field
          trace_helper(span_key, platform_key, super_proc, **kwargs) do |span|
            kwargs[:query].provided_variables.each do |key, value|
              span.set_tag("graphql.variables.#{key}", value)
            end
          end
        else
          super_proc.call
        end
      end

      def execute_field(**kwargs)
        execute_field_span('resolve', proc { super(**kwargs) }, **kwargs)
      end

      def execute_field_lazy(**kwargs)
        execute_field_span('resolve_lazy', proc { super(**kwargs) }, **kwargs)
      end

      def authorized_span(span_key, super_proc, **kwargs)
        platform_key = @platform_key_cache[DataDogTrace].platform_authorized_key_cache[kwargs[:type]]
        trace_helper(span_key, platform_key, super_proc, **kwargs)
      end

      def authorized(**kwargs)
        authorized_span('authorized', proc { super(**kwargs) }, **kwargs)
      end

      def authorized_lazy(**kwargs)
        authorized_span('authorized_lazy', proc { super(**kwargs) }, **kwargs)
      end

      def resolve_type_span(span_key, super_proc, **kwargs)
        platform_key = @platform_key_cache[DataDogTrace].platform_resolve_type_key_cache[kwargs[:type]]
        trace_helper(span_key, platform_key, super_proc, **kwargs)
      end

      def resolve_type(**kwargs)
        resolve_type_span('resolve_type', proc { super(**kwargs) }, **kwargs)
      end

      def resolve_type_lazy(**kwargs)
        resolve_type_span('resolve_type_lazy', proc { super(**kwargs) }, **kwargs)
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
