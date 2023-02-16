# frozen_string_literal: true

module GraphQL
  module Tracing
    module PlatformTrace
      def initialize(trace_scalars: false, **_options)
        @trace_scalars = trace_scalars
        super
      end

      def platform_execute_field_lazy(platform_key, data, &block)
        platform_execute_field(platform_key, data, &block)
      end

      def platform_authorized_lazy(key, &block)
        platform_authorized(key, &block)
      end

      def platform_resolve_type_lazy(key, &block)
        platform_resolve_type(key, &block)
      end

      def self.included(child_class)
        [:execute_field, :execute_field_lazy].each do |field_trace_method|
          child_class.module_eval <<-RUBY, __FILE__, __LINE__
            def #{field_trace_method}(**data)
              field = data[:field]
              return_type = field.type.unwrap
              trace_field = if return_type.kind.scalar? || return_type.kind.enum?
                (field.trace.nil? && @trace_scalars) || field.trace
              else
                true
              end
              platform_key = if trace_field
                context = data[:query].context
                cached_platform_key(context, field, :field) { platform_field_key(field.owner, field) }
              else
                nil
              end
              if platform_key && trace_field
                platform_#{field_trace_method}(platform_key, data) do
                  super
                end
              else
                super
              end
            end
          RUBY
        end


        [:authorized, :authorized_lazy].each do |auth_trace_method|
          if !child_class.method_defined?(auth_trace_method)
            child_class.module_eval <<-RUBY, __FILE__, __LINE__
              def #{auth_trace_method}(type:, query:, object:)
                platform_key = cached_platform_key(query.context, type, :authorized) { platform_authorized_key(type) }
                platform_#{auth_trace_method}(platform_key) do
                  super
                end
              end
            RUBY
          end
        end

        [:resolve_type, :resolve_type_lazy].each do |rt_trace_method|
          if !child_class.method_defined?(rt_trace_method)
            child_class.module_eval <<-RUBY, __FILE__, __LINE__
              def #{rt_trace_method}(query:, type:, object:)
                platform_key = cached_platform_key(query.context, type, :resolve_type) { platform_resolve_type_key(type) }
                platform_#{rt_trace_method}(platform_key) do
                  super
                end
              end
            RUBY
          end
        end
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
