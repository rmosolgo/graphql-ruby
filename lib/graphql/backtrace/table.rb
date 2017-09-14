# frozen_string_literal: true
# test_via: ../backtrace.rb
module GraphQL
  module Backtrace
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

      def initialize(context)
        rows = [HEADERS]
        build_rows(context, rows: rows, top: true)
        @to_s = render_table(rows)
        @to_backtrace = rows.map { |r| "#{r[0]}: #{r[1]}" }
        # skip the header entry
        @to_backtrace.shift
      end

      # @return [String] A table layout of backtrace with metadata
      attr_reader :to_s

      # @return [Array<String>] An array of position + field name entries
      attr_reader :to_backtrace

      private

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
            col[0, max_len]
          end.join(" | ")
          table << "\n"
        end
        table
      end

      # @return [Array] 5 items for a backtrace table (not `key`)
      def build_rows(context_entry, rows:, top: false)
        case context_entry
        when GraphQL::Query::Context::FieldResolutionContext
          ctx = context_entry
          field_name = "#{ctx.irep_node.owner_type.name}.#{ctx.field.name}"
          position = "#{ctx.ast_node.line}:#{ctx.ast_node.col}"
          field_alias = ctx.ast_node.alias
          rows << [
            "#{position}",
            "#{field_name}#{field_alias ? " as #{field_alias}" : ""}",
            ctx.object.inspect,
            ctx.irep_node.arguments.to_h.inspect,
            top ? "(error)" : Backtrace::InspectResult.inspect(ctx.value),
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
          rows << [
            "#{position}",
            "#{op_type}#{op_name ? " #{op_name}" : ""}",
            query.root_value.inspect,
            query.variables.to_h.inspect,
            Backtrace::InspectResult.inspect(query.context.value),
          ]
        else
          raise "Unexpected get_rows subject #{context_entry.inspect}"
        end
      end
    end
  end
end
