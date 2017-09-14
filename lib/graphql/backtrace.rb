# frozen_string_literal: true
module GraphQL
  # Add GraphQL metadata to backtraces using `TracePoint`.
  #
  # WARNING: {.enable} is not threadsafe because {GraphQL::Tracing.install} is not threadsafe.
  #
  # @example toggling backtrace annotation
  #   # to enable:
  #   GraphQL::Backtrace.enable
  #   # later, to disable:
  #   GraphQL::Backtrace.disable
  #
  module Backtrace
    # When {Backtrace} is enabled,
    # raised errors are wrapped with `TracedError`.
    class TracedError < GraphQL::Error
      # @return [Array<String>] Printable backtrace of GraphQL error context
      attr_reader :graphql_backtrace

      # @return [Array<GraphQL::Execution::Multiplex, GraphQL::Query, GraphQL::Query::Context>] Objects which represent context
      attr_reader :graphql_context

      MESSAGE_TEMPLATE = <<-MESSAGE
Unhandled error during GraphQL execution: %{cause_message}.
Use #cause to access the original exception (including #cause.backtrace).

GraphQL Backtrace:

  %{graphql_backtrace}
MESSAGE

      def initialize(err, graphql_context)
        @graphql_context = graphql_context
        @graphql_backtrace = graphql_context.map do |key, ctx_entry|
          "#{(key + ":").ljust(20)} #{Backtrace.serialize_context_entry(ctx_entry)}"
        end
        message = MESSAGE_TEMPLATE % {
          cause_message: err.message,
          graphql_backtrace: graphql_backtrace.map { |l| "  " + l }.join("\n"),
        }
        super(message)
      end
    end
    module_function
    # Turn on annotation
    def enable
      execution_context.clear
      GraphQL::Tracing.install(self)
      nil
    end

    # Turn off annotation
    def disable
      GraphQL::Tracing.uninstall(self)
      nil
    end

    # Implement the {GraphQL::Tracing} API.
    def trace(key, metadata)
      push_data = case key
      when "lex", "parse"
        # No context here, don't have a query yet
        nil
      when "execute_multiplex", "analyze_multiplex"
        metadata[:multiplex].queries
      when "validate", "analyze_query", "execute_query", "execute_query_lazy"
        metadata[:query] || metadata[:queries]
      when "execute_field", "execute_field_lazy"
        metadata[:context]
      else
        # Custom key, no backtrace data for this
        nil
      end

      if push_data
        if key == "execute_multiplex"
          execution_context.clear
          execution_context.push([key, push_data])
          begin
            yield
          rescue StandardError => err
            # This is an unhandled error from execution,
            # Re-raise it with a GraphQL trace.
            graphql_backtrace = execution_context.dup.uniq.reverse
            raise TracedError.new(err, graphql_backtrace)
          ensure
            execution_context.clear
          end
        else
          execution_context.push([key, push_data])
          res = yield
          execution_context.pop
          res
        end
      else
        yield
      end
    end

    # A stack of objects corresponding to the GraphQL context.
    # The top of the stack is the context for the current methods.
    # If a method is called, that object will be added to `backtrace_context`
    # to go along with the new backtrace entry.
    # @return [Array<Object>]
    def execution_context
      Thread.current[:graphql_execution_context] ||= []
    end

    # Format `context_entry` into a readable string.
    # @param context_entry [Object] something that was pushed onto the stack during tracing
    # @return [String] something to add to the backtrace entry
    def serialize_context_entry(context_entry)
      case context_entry
      when GraphQL::Query::Context::FieldResolutionContext
        ctx = context_entry
        ctx_msg = "#{ctx.irep_node.owner_type.name}.#{ctx.field.name}"
        if ctx.ast_node.arguments.any?
          ctx_msg = "#{ctx_msg}(#{ctx.ast_node.arguments.map(&:to_query_string).join(", ")})"
        end

        field_alias = ctx.ast_node.alias
        if field_alias
          ctx_msg = "#{ctx_msg} (as #{field_alias})"
        end

        ctx_msg
      when GraphQL::Query
        op_type = (context_entry.selected_operation && context_entry.selected_operation.operation_type) || "query"
        op_name = context_entry.selected_operation_name || "<Anonymous>"
        "#{op_type} #{op_name}"
      when Array
        context_entry.map { |i| serialize_context_entry(i) }.join(", ")
      else
        raise "Unexpected context entry: #{context_entry}"
      end
    end
  end
end
