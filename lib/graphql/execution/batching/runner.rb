# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class Runner
        def initialize(schema, document, context, variables, root_object)
          @schema = schema
          @document = document
          @query = GraphQL::Query.new(schema, document: document, context: context, variables: variables, root_value: root_object)
          @context = @query.context
          @variables = variables
          @root_object = root_object
          @path = []
          @steps_queue = []
          @data = {}
          @runtime_types_at_result = {}.compare_by_identity
          @static_types_at_result = {}.compare_by_identity
          @selected_operation = nil
          @root_type = nil
          @dataloader = @context[:dataloader] ||= schema.dataloader_class.new
          @resolves_lazies = @schema.resolves_lazies?
          @field_resolve_step_class = @schema.uses_raw_value? ? RawValueFieldResolveStep : FieldResolveStep
        end

        def add_step(step)
          @dataloader.append_job(step)
        end

        attr_reader :steps_queue, :schema, :context, :variables, :static_types_at_result, :runtime_types_at_result, :dataloader, :resolves_lazies

        def execute
          @selected_operation = @document.definitions.first # TODO select named operation
          isolated_steps = case @selected_operation.operation_type
          when nil, "query"
            [
              SelectionsStep.new(
                parent_type: @root_type = @schema.query,
                selections: @selected_operation.selections,
                objects: [@root_object],
                results: [@data],
                path: EmptyObjects::EMPTY_ARRAY,
                runner: self,
              )
            ]
          when "mutation"
            fields = {}
            gather_selections(@schema.mutation, @selected_operation.selections, nil, into: fields)
            fields.each_value.map do |field_resolve_step|
              SelectionsStep.new(
                parent_type: @root_type = @schema.mutation,
                selections: field_resolve_step.ast_nodes || Array(field_resolve_step.ast_node),
                objects: [@root_object],
                results: [@data],
                path: EmptyObjects::EMPTY_ARRAY,
                runner: self,
              )
            end
          when "subscription"
            raise ArgumentError, "TODO implement subscriptions"
          else
            raise ArgumentError, "Unhandled operation type: #{operation.operation_type.inspect}"
          end

          while (next_isolated_step = isolated_steps.shift)
            add_step(next_isolated_step)
            @dataloader.run
          end

          result = if @context.errors.empty?
            {
              "data" => @data
            }
          else
            data = propagate_errors(@data, @context.errors)
            errors = []
            @context.errors.each do |err|
              if err.respond_to?(:to_h)
                errors << err.to_h
              end
            end
            res_h = {}
            if !errors.empty?
              res_h["errors"] = errors
            end
            res_h["data"] = data
            res_h
          end

          GraphQL::Query::Result.new(query: @query, values: result)
        end

        def gather_selections(type_defn, ast_selections, selections_step, into:)
          ast_selections.each do |ast_selection|
            next if !directives_include?(ast_selection)
            case ast_selection
            when GraphQL::Language::Nodes::Field
              key = ast_selection.alias || ast_selection.name
              step = into[key] ||= @field_resolve_step_class.new(
                selections_step: selections_step,
                key: key,
                parent_type: type_defn,
                runner: self,
              )
              step.append_selection(ast_selection)
            when GraphQL::Language::Nodes::InlineFragment
              type_condition = ast_selection.type&.name
              if type_condition.nil? || type_condition_applies?(type_defn, type_condition)
                gather_selections(type_defn, ast_selection.selections, selections_step, into: into)
              end
            when GraphQL::Language::Nodes::FragmentSpread
              fragment_definition = @document.definitions.find { |defn| defn.is_a?(GraphQL::Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
              type_condition = fragment_definition.type.name
              if type_condition_applies?(type_defn, type_condition)
                gather_selections(type_defn, fragment_definition.selections, selections_step, into: into)
              end
            else
              raise ArgumentError, "Unsupported graphql selection node: #{ast_selection.class} (#{ast_selection.inspect})"
            end
          end
        end

        def add_non_null_error(type, field, ast_node, is_from_array, path)
          err = InvalidNullError.new(type, field, ast_node, is_from_array: is_from_array, path: path)
          @schema.type_error(err, @context)
        end

        private

        def propagate_errors(data, errors)
          paths_to_check = errors.map(&:path)
          check_object_result(data, @root_type, @selected_operation.selections, [], [], paths_to_check)
        end

        def check_object_result(result_h, static_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
          current_path_len = current_exec_path.length
          ast_selections.each do |ast_selection|
            case ast_selection
            when Language::Nodes::Field
              begin
                key = ast_selection.alias || ast_selection.name
                current_exec_path << key
                current_result_path << key
                if paths_to_check.any? { |path_to_check| path_to_check[current_path_len] == key }
                  result_value = result_h[key]
                  field_defn = @context.types.field(static_type, ast_selection.name)
                  result_type = field_defn.type
                  if (result_type_non_null = result_type.non_null?)
                    result_type = result_type.of_type
                  end

                  new_result_value = if result_value.is_a?(GraphQL::Error)
                    result_value.path = current_result_path.dup
                    nil
                  else
                    if result_type.list?
                      check_list_result(result_value, result_type.of_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
                    elsif result_type.kind.leaf?
                      result_value
                    else
                      check_object_result(result_value, result_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
                    end
                  end

                  if new_result_value.nil? && result_type_non_null
                    return nil
                  else
                    result_h[key] = new_result_value
                  end
                end
              ensure
                current_exec_path.pop
                current_result_path.pop
              end
            when Language::Nodes::InlineFragment
              static_type_at_result = @static_types_at_result[result_h]
              if type_condition_applies?(static_type_at_result, ast_selection.type.name)
                result_h = check_object_result(result_h, static_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
              end
            when Language::Nodes::FragmentSpread
              fragment_defn = @document.definitions.find { |defn| defn.is_a?(Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
              static_type_at_result = @static_types_at_result[result_h]
              if type_condition_applies?(static_type_at_result, fragment_defn.type.name)
                result_h = check_object_result(result_h, static_type, fragment_defn.selections, current_exec_path, current_result_path, paths_to_check)
              end
            end
          end

          result_h
        end

        def check_list_result(result_arr, inner_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
          inner_type_non_null = false
          if inner_type.non_null?
            inner_type_non_null = true
            inner_type = inner_type.of_type
          end

          new_invalid_null = false
          result_arr.map!.with_index do |result_item, idx|
            current_result_path << idx
            new_result = if result_item.is_a?(GraphQL::Error)
              result_item.path = current_result_path.dup
              nil
            elsif inner_type.list?
              check_list_result(result_item, inner_type.of_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
            elsif inner_type.kind.leaf?
              result_item
            else
              check_object_result(result_item, inner_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
            end

            if new_result.nil? && inner_type_non_null
              new_invalid_null = true
              break
            else
              new_result
            end
          ensure
            current_result_path.pop
          end

          if new_invalid_null
            nil
          else
            result_arr
          end
        end

        def dir_arg_value(arg_node)
          if arg_node.value.is_a?(Language::Nodes::VariableIdentifier)
            var_key = arg_node.value.name
            if @variables.key?(var_key)
              @variables[var_key]
            else
              @variables[var_key.to_sym]
            end
          else
            arg_node.value
          end
        end
        def directives_include?(ast_selection)
          if ast_selection.directives.any? { |dir_node|
                if dir_node.name == "skip"
                  dir_node.arguments.any? { |arg_node| arg_node.name == "if" && dir_arg_value(arg_node) == true } # rubocop:disable Development/ContextIsPassedCop
                elsif dir_node.name == "include"
                  dir_node.arguments.any? { |arg_node| arg_node.name == "if" && dir_arg_value(arg_node) == false } # rubocop:disable Development/ContextIsPassedCop
                end
              }
            false
          else
            true
          end
        end

        def type_condition_applies?(concrete_type, type_name)
          if type_name == concrete_type.graphql_name
            true
          else
            abs_t = @schema.get_type(type_name, @context)
            p_types = @schema.possible_types(abs_t, @context)
            p_types.include?(concrete_type)
          end
        end
      end
    end
  end
end
