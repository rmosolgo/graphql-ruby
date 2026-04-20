# frozen_string_literal: true
module GraphQL
  module Execution
    class Finalize
      def initialize(query, data, runner)
        @query = query
        @data = data
        @static_type_at = runner.static_type_at
        @runner = runner
        @current_exec_path = query.path.dup
        @current_result_path = query.path.dup
        @finalizers = runner.finalizers ? runner.finalizers[query] : {}.compare_by_identity
        @finalizers_count = 0
        @finalizers.each do |key, values|
          values.each do |key2, values2|
            case values2
            when Array
              @finalizers_count += values2.size
            else
              @finalizers_count += 1
            end
          end
        end

        query.context.errors.each do |err|
          err_path = err.path - @current_exec_path
          key = err_path.pop
          targets = [data]
          while (part = err_path.shift)
            targets.map! { |t| t[part] }
            targets.flatten!
          end

          targets.each_with_index do |target, idx|
            if target.is_a?(Hash)
              if target[key].equal?(err)
                tf = @finalizers[target] ||= {}.compare_by_identity
                tf[key] = err
                @finalizers_count += 1
              elsif (arr = target[key]).is_a?(Array)
                arr.each_with_index do |el, idx|
                  if el.equal?(err)
                    tf = @finalizers[arr] ||= {}.compare_by_identity
                    tf[idx] = err
                    @finalizers_count += 1
                  end
                end
              end
            end
          end
        end
      end

      def run
        if (selected_operation = @query.selected_operation) && @data
          if @data.is_a?(Hash)
            check_object_result(@data, @query.root_type, selected_operation.selections)
          elsif @data.is_a?(Array)
            check_list_result(@data, @query.root_type, selected_operation.selections)
          elsif @data.is_a?(Finalizer)
            dummy_data = {}
            dummy_key = "__dummy"
            @data.path = @query.path
            @data.finalize_graphql_result(@query, dummy_data, dummy_key)
            dummy_data[dummy_key]
          else
            raise ArgumentError, "Unexpected @data: #{@data.inspect}"
          end
        else
          @data
        end
      end

      private

      def run_finalizers(result_path, finalizer_or_finalizers, result_data, result_key)
        if finalizer_or_finalizers.is_a?(Array)
          finalizer_or_finalizers.each { |f|
            f.path = result_path
            f.finalize_graphql_result(@query, result_data, result_key)
          }
          @finalizers_count -= finalizer_or_finalizers.size
        else
          f = finalizer_or_finalizers
          f.path = result_path
          f.finalize_graphql_result(@query, result_data, result_key)
          @finalizers_count -= 1
        end
      end

      def finalizers(result_value, key)
        finalizers_for_value = @finalizers[result_value]
        finalizers_for_value && finalizers_for_value[key]
      end

      def check_object_result(result_h, parent_type, ast_selections)
        if (f = finalizers(result_h, nil))
          run_finalizers(@current_result_path.dup, f, result_h, nil)
          return result_h if @finalizers_count == 0
        end

        if parent_type.kind.abstract?
          parent_type = @runner.runtime_type_at[result_h]
        end

        ast_selections.each do |ast_selection|
          case ast_selection
          when Language::Nodes::Field
            key = ast_selection.alias || ast_selection.name
            if (f = finalizers(result_h, key))
              result_value = result_h[key]
              run_finalizers(@current_result_path.dup << key, f, result_h, key)
              new_result_value = result_h.key?(key) ? result_h[key] : :unassigned
            end
            next if !(f || result_h.key?(key))
            begin
              @current_exec_path << key
              @current_result_path << key

              field_defn = @query.context.types.field(parent_type, ast_selection.name) || raise("Invariant: No field found for #{static_type.to_type_signature}.#{ast_selection.name}")
              result_type = field_defn.type
              if (result_type_non_null = result_type.non_null?)
                result_type = result_type.of_type
              end

              if !f
                result_value = result_h[key]
                new_result_value = if result_type.list? && result_value
                  check_list_result(result_value, result_type.of_type, ast_selection.selections)
                elsif !result_type.kind.leaf? && result_value
                  check_object_result(result_value, result_type, ast_selection.selections)
                else
                  result_value
                end
              end

              if new_result_value.nil? && result_type_non_null
                return nil
              elsif :unassigned.equal?(new_result_value)
                # Do nothing
                break if @finalizers_count == 0
              elsif !new_result_value.equal?(result_value)
                result_h[key] = new_result_value
                break if @finalizers_count == 0
              end
            ensure
              @current_exec_path.pop
              @current_result_path.pop
            end
          when Language::Nodes::InlineFragment
            static_type_at_result = @static_type_at[result_h]
            if static_type_at_result && (
                (t = ast_selection.type).nil? ||
                @runner.type_condition_applies?(@query.context, static_type_at_result, t.name)
              )
              result_h = check_object_result(result_h, parent_type, ast_selection.selections)
            end
          when Language::Nodes::FragmentSpread
            fragment_defn = @query.document.definitions.find { |defn| defn.is_a?(Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
            static_type_at_result = @static_type_at[result_h]
            if static_type_at_result && @runner.type_condition_applies?(@query.context, static_type_at_result, fragment_defn.type.name)
              result_h = check_object_result(result_h, parent_type, fragment_defn.selections)
            end
          end
        end

        result_h
      end

      def check_list_result(result_arr, inner_type, ast_selections)
        inner_type_non_null = false
        if inner_type.non_null?
          inner_type_non_null = true
          inner_type = inner_type.of_type
        end

        new_invalid_null = false

        if (f = finalizers(result_arr, nil))
          run_finalizers(@current_result_path.dup, f, result_arr, nil)
          return result_arr if @finalizers_count == 0
        end

        result_arr.each_with_index do |result_item, idx|
          @current_result_path << idx
          new_result = if (f = finalizers(result_arr, idx))
            run_finalizers(@current_result_path.dup, f, result_arr, idx)
            result_arr[idx]
          elsif inner_type.list? && result_item
            check_list_result(result_item, inner_type.of_type, ast_selections)
          elsif !inner_type.kind.leaf? && result_item
            check_object_result(result_item, inner_type, ast_selections)
          else
            result_item
          end

          if new_result.nil? && inner_type_non_null
            new_invalid_null = true
            result_arr[idx] = nil
            break if @finalizers_count == 0
          elsif !new_result.equal?(result_item)
            result_arr[idx] = new_result
            break if @finalizers_count == 0
          end
        ensure
          @current_result_path.pop
        end

        if new_invalid_null
          nil
        else
          result_arr
        end
      end
    end
  end
end
