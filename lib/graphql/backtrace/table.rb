# frozen_string_literal: true
module GraphQL
  class Backtrace
    # A class for turning a context into a human-readable table or array
    class Table
      MIN_COL_WIDTH = 4
      MAX_COL_WIDTH = 100
      HEADERS = [
        "Loc",
        "Field",
        "Object",
        "Arguments",
        "Result",
      ]

      def initialize(context, value:)
        @context = context
        @override_value = value
      end

      # @return [String] A table layout of backtrace with metadata
      def to_table
        @to_table ||= render_table(rows)
      end

      # @return [Array<String>] An array of position + field name entries
      def to_backtrace
        @to_backtrace ||= begin
          backtrace = rows.map { |r| "#{r[0]}: #{r[1]}" }
          # skip the header entry
          backtrace.shift
          backtrace
        end
      end

      private

      def rows
        @rows ||= build_rows(@context, rows: [HEADERS], top: true)
      end

      # @return [String]
      def render_table(rows)
        max = Array.new(HEADERS.length, MIN_COL_WIDTH)

        rows.each do |row|
          row.each_with_index do |col, idx|
            col_len = col.length
            max_len = max[idx]
            if col_len > max_len
              if col_len > MAX_COL_WIDTH
                max[idx] = MAX_COL_WIDTH
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
            if col.length > max_len
              col = col[0, max_len - 3] + "..."
            end
            col
          end.join(" | ")
          table << "\n"
        end
        table
      end

      # @return [Array] 5 items for a backtrace table (not `key`)
      def build_rows(context_entry, rows:, top: false)
        case context_entry
        when Backtrace::Frame
          field_alias = context_entry.ast_node.respond_to?(:alias) && context_entry.ast_node.alias
          value = if top && @override_value
            @override_value
          else
            @context.query.context.namespace(:interpreter)[:runtime].value_at(context_entry.path)
          end
          rows << [
            "#{context_entry.ast_node ? context_entry.ast_node.position.join(":") : ""}",
            "#{context_entry.field.path}#{field_alias ? " as #{field_alias}" : ""}",
            "#{context_entry.object.object.inspect}",
            context_entry.arguments.to_h.inspect,
            Backtrace::InspectResult.inspect_result(value),
          ]
          if (parent = context_entry.parent_frame)
            build_rows(parent, rows: rows)
          else
            rows
          end
        when GraphQL::Query::Context::FieldResolutionContext
          ctx = context_entry
          field_name = "#{ctx.irep_node.owner_type.name}.#{ctx.field.name}"
          position = "#{ctx.ast_node.line}:#{ctx.ast_node.col}"
          field_alias = ctx.ast_node.alias
          object = ctx.object
          if object.is_a?(GraphQL::Schema::Object)
            object = object.object
          end
          rows << [
            "#{position}",
            "#{field_name}#{field_alias ? " as #{field_alias}" : ""}",
            "#{object.inspect}",
            ctx.irep_node.arguments.to_h.inspect,
            Backtrace::InspectResult.inspect_result(top && @override_value ? @override_value : ctx.value),
          ]

          build_rows(ctx.parent, rows: rows)
        when GraphQL::Query::Context
          query = context_entry.query
          op = query.selected_operation
          if op
            op_type = op.operation_type
            position = "#{op.line}:#{op.col}"
          else
            op_type = "query"
            position = "?:?"
          end
          op_name = query.selected_operation_name
          object = query.root_value
          if object.is_a?(GraphQL::Schema::Object)
            object = object.object
          end
          value = context_entry.namespace(:interpreter)[:runtime].value_at([])
          rows << [
            "#{position}",
            "#{op_type}#{op_name ? " #{op_name}" : ""}",
            "#{object.inspect}",
            query.variables.to_h.inspect,
            Backtrace::InspectResult.inspect_result(value),
          ]
        else
          raise "Unexpected get_rows subject #{context_entry.class} (#{context_entry.inspect})"
        end
      end
    end
  end
end
