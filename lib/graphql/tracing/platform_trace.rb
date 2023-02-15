# frozen_string_literal: true

module GraphQL
  module Tracing
    module PlatformTrace
      class << self
        attr_accessor :platform_keys, :options

        def inherited(child_class)
          child_class.platform_keys = self.platform_keys
        end
      end

      def initialize
        @trace_scalars = self.class.options.fetch(:trace_scalars, false)
        super
      end

      [
        :lex, :parse, :validate,
        :analyze_query, :analyze_multiplex,
        :execute_multiplex, :execute_query, :execute_query_lazy,
        # :execute_field, :execute_field_lazy,
        :authorized, :authorized_lazy,
        :resolve_type, :resolve_type_lazy,
      ].each do |trace_method|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{trace_method}(**kwargs)
            @#{trace_method}_key ||= @platform_keys.fetch("#{trace_method}")
            platform_trace(@#{trace_method}_key, **kwargs) do
              yield
            end
          end
        RUBY
      end

      [:execute_field, :execute_field_lazy].each do |field_trace_method|
        module_eval <<-RUBY, __FILE__, __LINE__
          def #{field_trace_method}(field:, query:, **_rest)
            return_type = field.type.unwrap
            trace_field = if return_type.kind.scalar? || return_type.kind.enum?
              (field.trace.nil? && @trace_scalars) || field.trace
            else
              true
            end

            platform_key = if trace_field
              context = query.context
              cached_platform_key(context, field, :field) { platform_field_key(field.owner, field) }
            else
              nil
            end

            if platform_key && trace_field
              # TODO data here ?
              data = {}
              platform_trace(platform_key, "#{field_trace_method}", data) do
                yield
              end
            else
              yield
            end
          end
        RUBY
      end

      [:authorized, :authorized_lazy].each do |auth_trace_method|
        module_eval <<-RUBY, __FILE__, __LINE__
        def #{auth_trace_method}(type:, query:, **rest)
          @#{auth_trace_method}_key ||= @platform_keys.fetch("#{auth_trace_method}")
          platform_key = cached_platform_key(query.context, type, :authorized) { platform_authorized_key(type) }
          # TODO Data here?
          platform_trace(@#{auth_trace_method}_key, data = {}) do
            yield
          end
        end
        RUBY
      end

      [:resolve_type, :resolve_type_lazy].each do |resolve_type_trace_method|
        module_eval <<-RUBY, __FILE__, __LINE__
        def #{resolve_type_trace_method}(type:, query:, **rest)
          @#{resolve_type_trace_method}_key ||= @platform_keys.fetch("#{resolve_type_trace_method}")
          platform_key = cached_platform_key(query.context, type, :resolve_type) { platform_authorized_key(type) }
          # TODO Data here?
          platform_trace(@#{resolve_type_trace_method}_key, data = {}) do
            yield
          end
        end
        RUBY
      end

      private

      # Get the transaction name based on the operation type and name if possible, or fall back to a user provided
      # one. Useful for anonymous queries.
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

      attr_reader :options

      # Different kind of schema objects have different kinds of keys:
      #
      # - Object types: `.authorized`
      # - Union/Interface types: `.resolve_type`
      # - Fields: execution
      #
      # So, they can all share one cache.
      #
      # If the key isn't present, the given block is called and the result is cached for `key`.
      #
      # @param ctx [GraphQL::Query::Context]
      # @param key [Class, GraphQL::Field] A part of the schema
      # @param trace_phase [Symbol] The stage of execution being traced (used by OpenTelementry tracing)
      # @return [String]
      def cached_platform_key(ctx, key, trace_phase)
        cache = ctx.namespace(self.class)[:platform_key_cache] ||= {}
        cache.fetch(key) { cache[key] = yield }
      end
    end
  end
end
