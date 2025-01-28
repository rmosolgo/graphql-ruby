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
        @rows ||= begin
          query = @context.query
          query_ctx = @context
          runtime_inst = query_ctx.namespace(:interpreter_runtime)[:runtime]
          result = runtime_inst.instance_variable_get(:@response)
          rows = []
          result_path = []
          last_part = nil
          path = @context.current_path
          path.each do |path_part|
            value = value_at(runtime_inst, result_path)

            if result_path.empty?
              name = query.selected_operation.operation_type || "query"
              if (n = query.selected_operation_name)
                name += " #{n}"
              end
              args = query.variables
            else
              name = result.graphql_field.path
              args = result.graphql_arguments
            end

            object = result.graphql_parent ? result.graphql_parent.graphql_application_value : result.graphql_application_value
            object = object.object.inspect

            rows << [
              result.ast_node.position.join(":"),
              name,
              "#{object}",
              args.to_h.inspect,
              Backtrace::InspectResult.inspect_result(value),
            ]

            result_path << path_part
            if path_part == path.last
              last_part = path_part
            else
              result = result[path_part]
            end
          end

          if last_part
            object = result.graphql_application_value.object.inspect
            ast_node = result.graphql_selections.find { |s| s.alias == last_part || s.name == last_part }
            field_defn = query.get_field(result.graphql_result_type, ast_node.name)
            if field_defn
              args = query.arguments_for(ast_node, field_defn).to_h
              field_path = field_defn.path
              if ast_node.alias
                field_path += " as #{ast_node.alias}"
              end
            else
              args = {}
              field_path = "#{result.graphql_result_type.graphql_name}.#{last_part}"
            end

            rows << [
              ast_node.position.join(":"),
              field_path,
              "#{object}",
              args.inspect,
              Backtrace::InspectResult.inspect_result(@override_value)
            ]
          end
          rows << HEADERS
          rows.reverse!
          rows
        end
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
            value_at(@context.query.context.namespace(:interpreter_runtime)[:runtime], context_entry.path)
          end
          rows << [
            "#{context_entry.ast_node ? context_entry.ast_node.position.join(":") : ""}",
            "#{context_entry.field.path}#{field_alias ? " as #{field_alias}" : ""}",
            "#{context_entry.object.object.inspect}",
            context_entry.arguments.to_h.inspect, # rubocop:disable Development/ContextIsPassedCop -- unrelated method
            Backtrace::InspectResult.inspect_result(value),
          ]
          if (parent = context_entry.parent_frame)
            build_rows(parent, rows: rows)
          else
            rows
          end
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
          value = value_at(context_entry.namespace(:interpreter_runtime)[:runtime], [])
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

      def value_at(runtime, path)
        response = runtime.final_result
        path.each do |key|
          if response && (response = response[key])
            next
          else
            break
          end
        end
        response
      end
    end
  end
end
