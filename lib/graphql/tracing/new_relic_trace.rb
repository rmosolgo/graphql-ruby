# frozen_string_literal: true

require "graphql/tracing/platform_trace"

module GraphQL
  module Tracing
    # A tracer for reporting GraphQL-Ruby time to New Relic
    #
    # @example Installing the tracer
    #   class MySchema < GraphQL::Schema
    #     trace_with GraphQL::Tracing::NewRelicTrace
    #
    #     # Optional, use the operation name to set the new relic transaction name:
    #     # trace_with GraphQL::Tracing::NewRelicTrace, set_transaction_name: true
    #   end
    #
    # @example Installing without trace events for `authorized?` or `resolve_type` calls
    #   trace_with GraphQL::Tracing::NewRelicTrace, trace_authorized: false, trace_resolve_type: false
    module NewRelicTrace
      # @param set_transaction_name [Boolean] If true, the GraphQL operation name will be used as the transaction name.
      #   This is not advised if you run more than one query per HTTP request, for example, with `graphql-client` or multiplexing.
      #   It can also be specified per-query with `context[:set_new_relic_transaction_name]`.
      # @param trace_authorized [Boolean] If `false`, skip tracing `authorized?` calls
      # @param trace_resolve_type [Boolean] If `false`, skip tracing `resolve_type?` calls
      # @param trace_scalars [Boolean] If `true`, Enum and Scalar fields will be traced by default
      def initialize(set_transaction_name: false, trace_authorized: true, trace_resolve_type: true, trace_scalars: false, **_rest)
        @set_transaction_name = set_transaction_name
        @trace_authorized = trace_authorized
        @trace_resolve_type = trace_resolve_type
        @trace_scalars = trace_scalars
        @nr_field_names = Hash.new do |h, field|
          h[field] = "GraphQL/#{field.owner.graphql_name}/#{field.graphql_name}"
        end.compare_by_identity

        @nr_authorized_names = Hash.new do |h, type|
          h[type] = "GraphQL/Authorized/#{type.graphql_name}"
        end.compare_by_identity

        @nr_resolve_type_names = Hash.new do |h, type|
          h[type] = "GraphQL/ResolveType/#{type.graphql_name}"
        end.compare_by_identity

        @nr_source_names = Hash.new do |h, source_inst|
          h[source_inst] = "GraphQL/Source/#{source_inst.class.name}"
        end.compare_by_identity

        @nr_parse = @nr_validate = @nr_analyze = @nr_execute = nil
        super
      end

      def begin_parse(query_str)
        @nr_parse = NewRelic::Agent::Tracer.start_transaction_or_segment(partial_name: "GraphQL/parse", category: :web)
        super
      end

      def end_parse(query_str)
        @nr_parse.finish
        super
      end

      def begin_validate(query, validate)
        @nr_validate = NewRelic::Agent::Tracer.start_transaction_or_segment(partial_name: "GraphQL/validate", category: :web)
        super
      end

      def end_validate(query, validate, validation_errors)
        @nr_validate.finish
        super
      end

      def begin_analyze_multiplex(multiplex, analyzers)
        @nr_analyze = NewRelic::Agent::Tracer.start_transaction_or_segment(partial_name: "GraphQL/analyze", category: :web)
        super
      end

      def end_analyze_multiplex(multiplex, analyzers)
        @nr_analyze.finish
        super
      end

      def begin_execute_multiplex(multiplex)
        query = multiplex.queries.first
        set_this_txn_name = query.context[:set_new_relic_transaction_name]
        if set_this_txn_name || (set_this_txn_name.nil? && @set_transaction_name)
          NewRelic::Agent.set_transaction_name(transaction_name(query))
        end
        @nr_execute = NewRelic::Agent::Tracer.start_transaction_or_segment(partial_name: "GraphQL/execute", category: :web)
        super
      end

      def end_execute_multiplex(multiplex)
        @nr_execute.finish
        super
      end

      def begin_execute_field(field, object, arguments, query)
        return_type = field.type.unwrap
        trace_field = if return_type.kind.scalar? || return_type.kind.enum?
          (field.trace.nil? && @trace_scalars) || field.trace
        else
          true
        end
        if trace_field
          start_segment(partial_name: @nr_field_names[field], category: :web)
        end
        super
      end

      def end_execute_field(field, objects, arguments, query, result)
        finish_segment
        super
      end

      def begin_authorized(type, obj, ctx)
        if @trace_authorized
          start_segment(partial_name: @nr_authorized_names[type], category: :web)
        end
        super
      end

      def end_authorized(type, obj, ctx, is_authed)
        if @trace_authorized
          finish_segment
        end
        super
      end

      def begin_resolve_type(type, value, context)
        if @trace_resolve_type
          start_segment(partial_name: @nr_resolve_type_names[type], category: :web)
        end
        super
      end

      def end_resolve_type(type, value, context, resolved_type)
        if @trace_resolve_type
          finish_segment
        end
        super
      end

      def begin_dataloader_source(source)
        start_segment(partial_name: @nr_source_names[source], category: :web)
        super
      end

      def end_dataloader_source(source)
        finish_segment
        super
      end

      def dataloader_fiber_yield(source)
        prev_segment = finish_segment
        Fiber[:graphql_nr_previous_segment] = prev_segment
        super
      end

      def dataloader_fiber_resume(source)
        prev_segment = Fiber[:graphql_nr_previous_segment]
        Fiber[:graphql_nr_previous_segment] = nil
        if prev_segment
          seg_partial_name = prev_segment.name.sub(/^.*(GraphQL.*)$/, '\1')
          start_segment(partial_name: seg_partial_name, category: :web)
        end
        super
      end

      private

      def start_segment(...)
        Fiber[:graphql_nr_segment] = NewRelic::Agent::Tracer.start_transaction_or_segment(...)
      end

      def finish_segment
        segment = Fiber[:graphql_nr_segment]
        if segment
          segment.finish
          Fiber[:graphql_nr_segment] = nil
          segment
        end
      end

      def transaction_name(query)
        selected_op = query.selected_operation
        txn_name = if selected_op
          op_type = selected_op.operation_type
          op_name = selected_op.name || fallback_transaction_name(query.context) || "anonymous"
          "#{op_type}.#{op_name}"
        else
          "query.anonymous"
        end
        "GraphQL/#{txn_name}"
      end

      def fallback_transaction_name(context)
        context[:tracing_fallback_transaction_name]
      end
    end
  end
end
