# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class Runner
        def initialize(multiplex)
          @multiplex = multiplex
          @schema = multiplex.schema
          @steps_queue = []
          @runtime_types_at_result = {}.compare_by_identity
          @static_types_at_result = {}.compare_by_identity
          @selected_operation = nil
          @dataloader = multiplex.context[:dataloader] ||= @schema.dataloader_class.new
          @resolves_lazies = @schema.resolves_lazies?
          @field_resolve_step_class = @schema.uses_raw_value? ? RawValueFieldResolveStep : FieldResolveStep
          @authorizes = {}.compare_by_identity
        end

        def add_step(step)
          @dataloader.append_job(step)
        end

        attr_reader :steps_queue, :schema, :variables, :static_types_at_result, :runtime_types_at_result, :dataloader, :resolves_lazies, :authorizes

        def execute
          Fiber[:__graphql_current_multiplex] = @multiplex
          isolated_steps = [[]]
          trace = @multiplex.current_trace
          queries = @multiplex.queries
          multiplex_analyzers = @schema.multiplex_analyzers
          if @multiplex.max_complexity
            multiplex_analyzers += [GraphQL::Analysis::MaxQueryComplexity]
          end

          trace.execute_multiplex(multiplex: @multiplex) do
            trace.begin_analyze_multiplex(@multiplex, multiplex_analyzers)
            @schema.analysis_engine.analyze_multiplex(@multiplex, multiplex_analyzers)
            trace.end_analyze_multiplex(@multiplex, multiplex_analyzers)

            results = []
            queries.each do |query|
              if query.validate && !query.valid?
                results << {
                  "errors" => query.static_errors.map(&:to_h)
                }
                next
              end

              selected_operation = query.document.definitions.first # TODO select named operation
              data = {}

              root_type = case selected_operation.operation_type
              when nil, "query"
                @schema.query
              when "mutation"
                @schema.mutation
              when "subscription"
                @schema.subscription
              else
                raise ArgumentError, "Unknown operation type: #{selected_operation.operation_type.inspect}"
              end

              auth_check = schema.sync_lazy(root_type.authorized?(query.root_value, query.context))
              root_value = if auth_check
                query.root_value
              else
                begin
                  auth_err = GraphQL::UnauthorizedError.new(object: query.root_value, type: root_type, context: query.context)
                  new_val = schema.unauthorized_object(auth_err)
                  if new_val
                    auth_check = true
                  end
                  new_val
                rescue GraphQL::ExecutionError => ex_err
                  # The old runtime didn't add path and ast_nodes to this
                  query.context.add_error(ex_err)
                  nil
                end
              end

              if !auth_check
                results << {}
                next
              end

              results << { "data" => data }

              case selected_operation.operation_type
              when nil, "query"
                isolated_steps[0] << SelectionsStep.new(
                  parent_type: root_type,
                  selections: selected_operation.selections,
                  objects: [root_value],
                  results: [data],
                  path: EmptyObjects::EMPTY_ARRAY,
                  runner: self,
                  query: query,
                )
              when "mutation"
                fields = {}
                gather_selections(root_type, selected_operation.selections, nil, query, {}, into: fields)
                fields.each_value do |field_resolve_step|
                  isolated_steps << [SelectionsStep.new(
                    parent_type: root_type,
                    selections: field_resolve_step.ast_nodes || Array(field_resolve_step.ast_node),
                    objects: [root_value],
                    results: [data],
                    path: EmptyObjects::EMPTY_ARRAY,
                    runner: self,
                    query: query,
                  )]
                end
              when "subscription"
                raise ArgumentError, "TODO implement subscriptions"
              else
                raise ArgumentError, "Unhandled operation type: #{operation.operation_type.inspect}"
              end

              @static_types_at_result[data] = root_type
              @runtime_types_at_result[data] = root_type

              # TODO This is stupid but makes multiplex_spec.rb pass
              trace.execute_query(query: query) do
              end
            end

            while (next_isolated_steps = isolated_steps.shift)
              next_isolated_steps.each do |step|
                add_step(step)
              end
              @dataloader.run
            end

            # TODO This is stupid but makes multiplex_spec.rb pass
            trace.execute_query_lazy(query: nil, multiplex: @multiplex) do
            end

            queries.each_with_index.map do |query, idx|
              result = results[idx]
              fin_result = if query.context.errors.empty?
                result
              else
                data = result["data"]
                data = propagate_errors(data, query)
                errors = []
                query.context.errors.each do |err|
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

              GraphQL::Query::Result.new(query: query, values: fin_result)
            end
          end
        ensure
          Fiber[:__graphql_current_multiplex] = nil
        end

        def gather_selections(type_defn, ast_selections, selections_step, query, prototype_result, into:)
          ast_selections.each do |ast_selection|
            next if !directives_include?(query, ast_selection)
            case ast_selection
            when GraphQL::Language::Nodes::Field
              key = ast_selection.alias || ast_selection.name
              step = into[key] ||= begin
                prototype_result[key] = nil

                @field_resolve_step_class.new(
                  selections_step: selections_step,
                  key: key,
                  parent_type: type_defn,
                  runner: self,
                )
              end
              step.append_selection(ast_selection)
            when GraphQL::Language::Nodes::InlineFragment
              type_condition = ast_selection.type&.name
              if type_condition.nil? || type_condition_applies?(query.context, type_defn, type_condition)
                gather_selections(type_defn, ast_selection.selections, selections_step, query, prototype_result, into: into)
              end
            when GraphQL::Language::Nodes::FragmentSpread
              fragment_definition = query.document.definitions.find { |defn| defn.is_a?(GraphQL::Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
              type_condition = fragment_definition.type.name
              if type_condition_applies?(query.context, type_defn, type_condition)
                gather_selections(type_defn, fragment_definition.selections, selections_step, query, prototype_result, into: into)
              end
            else
              raise ArgumentError, "Unsupported graphql selection node: #{ast_selection.class} (#{ast_selection.inspect})"
            end
          end
        end

        private

        def propagate_errors(data, query)
          paths_to_check = query.context.errors.map(&:path)
          paths_to_check.compact! # root-level auth errors currently come without a path
          # TODO dry with above?
          # This is also where a query-level "Step" would be used?
          selected_operation = query.document.definitions.first # TODO pick a selected operation
          root_type = case selected_operation.operation_type
          when nil, "query"
            query.schema.query
          when "mutation"
            query.schema.mutation
          when "subscription"
            raise "Not implemented yet, TODO"
          end
          check_object_result(query, data, root_type, selected_operation.selections, [], [], paths_to_check)
        end

        def check_object_result(query, result_h, static_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
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
                  field_defn = query.context.types.field(static_type, ast_selection.name)
                  result_type = field_defn.type
                  if (result_type_non_null = result_type.non_null?)
                    result_type = result_type.of_type
                  end
                  new_result_value = if result_value.is_a?(GraphQL::Error)
                    result_value.path = current_result_path.dup
                    nil
                  else
                    if result_type.list?
                      check_list_result(query, result_value, result_type.of_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
                    elsif result_type.kind.leaf?
                      result_value
                    else
                      check_object_result(query, result_value, result_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
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
              if static_type_at_result && type_condition_applies?(query.context, static_type_at_result, ast_selection.type.name)
                result_h = check_object_result(query, result_h, static_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
              end
            when Language::Nodes::FragmentSpread
              fragment_defn = query.document.definitions.find { |defn| defn.is_a?(Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
              static_type_at_result = @static_types_at_result[result_h]
              if static_type_at_result && type_condition_applies?(query.context, static_type_at_result, fragment_defn.type.name)
                result_h = check_object_result(query, result_h, static_type, fragment_defn.selections, current_exec_path, current_result_path, paths_to_check)
              end
            end
          end

          result_h
        end

        def check_list_result(query, result_arr, inner_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
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
              check_list_result(query, result_item, inner_type.of_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
            elsif inner_type.kind.leaf?
              result_item
            else
              check_object_result(query, result_item, inner_type, ast_selections, current_exec_path, current_result_path, paths_to_check)
            end

            if new_result.nil? && inner_type_non_null
              new_invalid_null = true
              nil
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

        def dir_arg_value(query, arg_node)
          if arg_node.value.is_a?(Language::Nodes::VariableIdentifier)
            var_key = arg_node.value.name
            if query.variables.key?(var_key)
              query.variables[var_key]
            else
              query.variables[var_key.to_sym]
            end
          else
            arg_node.value
          end
        end
        def directives_include?(query, ast_selection)
          if ast_selection.directives.any? { |dir_node|
                if dir_node.name == "skip"
                  dir_node.arguments.any? { |arg_node| arg_node.name == "if" && dir_arg_value(query, arg_node) == true } # rubocop:disable Development/ContextIsPassedCop
                elsif dir_node.name == "include"
                  dir_node.arguments.any? { |arg_node| arg_node.name == "if" && dir_arg_value(query, arg_node) == false } # rubocop:disable Development/ContextIsPassedCop
                end
              }
            false
          else
            true
          end
        end

        def type_condition_applies?(context, concrete_type, type_name)
          if type_name == concrete_type.graphql_name
            true
          else
            abs_t = @schema.get_type(type_name, context)
            p_types = @schema.possible_types(abs_t, context)
            c_p_types = @schema.possible_types(concrete_type, context)
            p_types.any? { |t| c_p_types.include?(t) }
          end
        end
      end
    end
  end
end
