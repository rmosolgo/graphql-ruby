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
    GRAPHQL_GEM_PATH = File.expand_path(File.join(__FILE__, ".."))
    module_function
    # Turn on annotation
    def enable
      clear_context_state
      GraphQL::Tracing.install(self)
      TRACE_POINT.enable
      nil
    end

    # Turn off annotation
    def disable
      GraphQL::Tracing.uninstall(self)
      TRACE_POINT.disable
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
          clear_context_state
        end
        execution_context.push(push_data)
        yield
      else
        yield
      end

    ensure
      if push_data
        execution_context.pop
      end
    end

    # A stack of objects, where each entry corresponds to an entry
    # in the backtrace.
    # The top of the stack corresponds to the top-most entry of the backtrace.
    # The backtrace may be longer than this stack; those extra
    # backtrace entries have no GraphQL context. (It may be longer
    # because the backtrace is non-zero when `.enable` is called.)
    # @return [Array<Object>]
    def backtrace_context
      Thread.current[:graphql_backtrace_context] ||= []
    end

    # A stack of objects corresponding to the GraphQL context.
    # The top of the stack is the context for the current methods.
    # If a method is called, that object will be added to `backtrace_context`
    # to go along with the new backtrace entry.
    # @return [Array<Object>]
    def execution_context
      Thread.current[:graphql_execution_context] ||= []
    end

    def clear_context_state
      execution_context.clear
      backtrace_context.clear
    end

    # - Gather info about method calls when they happen
    # - Remove trace info for this method when it returns
    # - Modify errors as they're being raised
    # @api private
    TRACE_POINT = TracePoint.new do |tp|
      case tp.event
      when :call, :b_call
        backtrace_context.push(execution_context.last)
      when :return, :b_return
        backtrace_context.pop
      when :raise
        annotate_error(tp.raised_exception)
        clear_context_state
      end
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

    # Apply styles to the string before it's added to the backtrace
    # @param context_message [String] A prepared string for the backtrace
    # @return [String] `context_message`, with styles added
    def format_context_message(context_message)
      " \e[1mGraphQL: #{context_message}\e[22m "
    end

    # Update `err`'s backtrace to include GraphQL-related annotations
    # @param err [StandardError]
    # @return [void]
    def annotate_error(err)
      ctx = backtrace_context
      if err.is_a?(NoMethodError)
        # Since it's a no-method-error, the `:call`
        # tracepoint was never entered.
        ctx.push(execution_context.last)
      end

      ctx_offset = ctx.length - 1
      new_backtrace = err.backtrace.each_with_index.map do |line,idx|
        ctx_entry = idx < ctx_offset && ctx[ctx_offset - idx]
        if ctx_entry
          ctx_msg = format_context_message(serialize_context_entry(ctx_entry))
          "#{line}#{ctx_msg}"
        else
          line
        end
      end
      err.set_backtrace(new_backtrace)
    rescue StandardError => err
      # We should never reach here, only if there's a bug in the block above!
      warn("GraphQL::Backtrace bug: #{err}")
      puts err.backtrace
    end
  end
end
