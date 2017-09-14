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
Unhandled error during GraphQL execution:

  %{cause_message}

Use #cause to access the original exception (including #cause.backtrace).

GraphQL Backtrace:
%{graphql_table}
MESSAGE

      def initialize(err, graphql_context)
        @graphql_context = graphql_context
        @graphql_backtrace = graphql_context.map do |key, ctx_entry|
          "#{(key + ":").ljust(20)} #{Backtrace.serialize_context_entry(ctx_entry)}"
        end
        message = MESSAGE_TEMPLATE % {
          cause_message: err.message,
          graphql_table: Table.render(@graphql_context)
        }
        super(message)
      end
    end

    module Table
      MAX_WIDTH = 50
      HEADERS = [
        "Event",
        "Field",
        "Object",
        "Arguments",
        "Result",
      ]

      def self.render(graphql_context)
        max = [10, 10, 10, 10, 10]
        rows = [HEADERS]
        graphql_context.each do |key, value|
          row = get_row(value)
          row.unshift(key)
          rows << row
        end

        rows.each do |row|
          row.each_with_index do |col, idx|
            col_len = col.length
            max_len = max[idx]
            if col_len > max_len
              if col_len > MAX_WIDTH
                max[idx] = MAX_WIDTH
              else
                max[idx] = col_len
              end
            end
          end
        end

        table = "".dup
        last_col_idx = max.length - 1
        rows.each do |row|
          table << row.map.each_with_index do |col, idx|
            max_len = max[idx]
            if idx < last_col_idx
              col = col.ljust(max_len)
            end
            col[0, max_len]
          end.join(" | ")
          table << "\n"
        end
        table
      end

      private

      # @return [Array] 4 items for a backtrace table (not `key`)
      def self.get_row(context_entry)
        case context_entry
        when GraphQL::Query::Context::FieldResolutionContext
          ctx = context_entry
          [
            Backtrace.serialize_context_entry(ctx),
            ctx.object.inspect,
            ctx.irep_node.arguments.to_h.inspect,
            ctx.value.inspect,
          ]
        when GraphQL::Query
          query = context_entry
          [
            Backtrace.serialize_context_entry(query),
            query.root_value.inspect,
            query.variables.to_h.inspect,
            "",
          ]
        when Array
          rows = context_entry.map { |v| get_row(v) }
          first_row = rows.shift
          if rows.any?
            # Calling zip with an empty array adds nils
            merged_rows = first_row.zip(rows)
            merged_rows.map {|r| r.join(", ") }
          else
            first_row
          end
        end
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
        field_name = "#{ctx.irep_node.owner_type.name}.#{ctx.field.name}"
        position = " @ [#{ctx.ast_node.line}:#{ctx.ast_node.col}]"
        field_alias = ctx.ast_node.alias
        "#{field_name}#{position}#{field_alias ? " as #{field_alias}" : ""}"
      when GraphQL::Query
        op = context_entry.selected_operation
        if op
          op_type = op.operation_type
          position = "#{op.line}:#{op.col}"
        else
          op_type = "query"
          position = "?:?"
        end
        op_name = context_entry.selected_operation_name
        "#{op_type}#{op_name ? " #{op_name}" : ""} @ [#{position}]"
      when Array
        context_entry.map { |i| serialize_context_entry(i) }.join(", ")
      else
        raise "Unexpected context entry: #{context_entry}"
      end
    end
  end
end
