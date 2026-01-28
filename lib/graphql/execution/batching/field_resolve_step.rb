# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class FieldResolveStep
        def initialize(parent_type:, runner:, key:, selections_step:)
          @selections_step = selections_step
          @key = key
          @parent_type = parent_type
          @ast_node = @ast_nodes = nil
          @objects = nil
          @results = nil
          @runner = runner
          @field_definition = nil
          @field_results = nil
          @path = nil
        end

        attr_writer :objects, :results

        attr_reader :ast_node, :ast_nodes, :key, :parent_type, :selections_step, :runner

        def path
          @path ||= [*@selections_step.path, @key].freeze
        end

        def append_selection(ast_node)
          if @ast_node.nil?
            @ast_node = ast_node
          elsif @ast_nodes.nil?
            @ast_nodes = [@ast_node, ast_node]
          else
            @ast_nodes << ast_node
          end
          nil
        end

        def coerce_arguments(argument_owner, ast_arguments_or_hash)
          arg_defns = argument_owner.arguments(@runner.context)
          if arg_defns.empty?
            return EmptyObjects::EMPTY_HASH
          end
          args_hash = {}
          if ast_arguments_or_hash.is_a?(Hash)
            ast_arguments_or_hash.each do |key, value|
              arg_defn = arg_defns.each_value.find { |a|
                a.keyword == key || a.graphql_name == String(key)
              }
              arg_value = coerce_argument_value(arg_defn.type, value)
              args_hash[arg_defn.original_keyword] = arg_value
            end
          else
            ast_arguments_or_hash.each { |arg_node|
              arg_defn = arg_defns[arg_node.name]
              arg_value = coerce_argument_value(arg_defn.type, arg_node.value)
              arg_key = arg_defn.original_keyword
              args_hash[arg_key] = arg_value
            }
          end

          arg_defns.each do |arg_graphql_name, arg_defn|
            if arg_defn.default_value? && !args_hash.key?(arg_defn.keyword)
              args_hash[arg_defn.keyword] = arg_defn.default_value
            end
          end

          args_hash
        end

        def coerce_argument_value(arg_t, arg_value)
          if arg_t.non_null?
            arg_t = arg_t.of_type
          end

          if arg_value.is_a?(Language::Nodes::VariableIdentifier)
            arg_value = if @runner.variables.key?(arg_value.name)
              @runner.variables[arg_value.name]
            elsif @runner.variables.key?(arg_value.name.to_sym)
              @runner.variables[arg_value.name.to_sym]
            end
          elsif arg_value.is_a?(Language::Nodes::NullValue)
            arg_value = nil
          elsif arg_value.is_a?(Language::Nodes::Enum)
            arg_value = arg_value.name
          elsif arg_value.is_a?(Language::Nodes::InputObject)
            arg_value = arg_value.arguments # rubocop:disable Development/ContextIsPassedCop
          end

          if arg_t.list?
            if arg_value.nil?
              arg_value
            else
              arg_value = Array(arg_value)
              inner_t = arg_t.of_type
              arg_value.map { |v| coerce_argument_value(inner_t, v) }
            end
          elsif arg_t.kind.leaf?
            arg_t.coerce_input(arg_value, @runner.context)
          elsif arg_t.kind.input_object?
            coerce_arguments(arg_t, arg_value)
          else
            raise "Unsupported argument value: #{arg_t.to_type_signature} / #{arg_value.class} (#{arg_value.inspect})"
          end
        end

        # Implement that Lazy API
        def value
          @field_results = sync(@field_results)
          @runner.add_step(self)
          true
        end

        def sync(lazy)
          if lazy.is_a?(Array)
            lazy.map! { |l| sync(l)}
          else
            @runner.schema.sync_lazy(lazy)
          end
        rescue GraphQL::ExecutionError => err
          err.path = path
          @runner.context.add_error(err)
          err
        end

        def call
          if @field_results
            build_results
          else
            field_name = @ast_node.name
            @field_definition = @runner.schema.get_field(@parent_type, field_name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")

            if field_name == "__typename"
              @field_results = Array.new(@objects.size, @parent_type.graphql_name)
              build_results
              return
            end

            arguments = coerce_arguments(@field_definition, @ast_node.arguments) # rubocop:disable Development/ContextIsPassedCop

            @field_results = @field_definition.resolve_batch(self, @objects, @runner.context, arguments)

            if @runner.resolves_lazies # TODO extract this
              lazies = false
              @field_results.each do |field_result|
                if @runner.schema.lazy?(field_result)
                  lazies = true
                  break
                elsif field_result.is_a?(Array)
                  field_result.each do |inner_fr|
                    if @runner.schema.lazy?(inner_fr)
                      break lazies = true
                    end
                  end
                  if lazies
                    break
                  end
                end
              end

              if lazies
                @runner.dataloader.lazy_at_depth(path.size, self)
              else
                build_results
              end
            else
              build_results
            end
          end
        end

        def build_results
          return_type = @field_definition.type
          return_result_type = return_type.unwrap

          if return_result_type.kind.composite?
            if @ast_nodes
              next_selections = []
              @ast_nodes.each do |ast_node|
                next_selections.concat(ast_node.selections)
              end
            else
              next_selections = @ast_node.selections
            end

            all_next_objects = []
            all_next_results = []

            is_list = return_type.list?
            is_non_null = return_type.non_null?
            @field_results.each_with_index do |result, i|
              result_h = @results[i]
              result_h[@key] = build_graphql_result(result, return_type, return_result_type, is_non_null, is_list, all_next_objects, all_next_results, false)
            end

            if !all_next_results.empty?
              all_next_objects.compact!

              if return_result_type.kind.abstract?
                next_objects_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
                next_results_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity

                all_next_objects.each_with_index do |next_object, i|
                  result = all_next_results[i]
                  object_type = @runner.runtime_types_at_result[result]
                  next_objects_by_type[object_type] << next_object
                  next_results_by_type[object_type] << result
                end

                next_objects_by_type.each do |obj_type, next_objects|
                  @runner.add_step(SelectionsStep.new(
                    path: path,
                    parent_type: obj_type,
                    selections: next_selections,
                    objects: next_objects,
                    results: next_results_by_type[obj_type],
                    runner: @runner,
                  ))
                end
              else
                @runner.add_step(SelectionsStep.new(
                  path: path,
                  parent_type: return_result_type,
                  selections: next_selections,
                  objects: all_next_objects,
                  results: all_next_results,
                  runner: @runner,
                ))
              end
            end
          else
            @field_results.each_with_index do |result, i|
              result_h = @results[i]
              result_h[@key] = if result.nil?
                if return_type.non_null?
                  @runner.add_non_null_error(@parent_type, @field_definition, @ast_node, false, path)
                else
                  nil
                end
              else
                # TODO `nil`s in [T!] types aren't handled
                return_type.coerce_result(result, @runner.context)
              end
            end
          end
        end

        private

        def build_graphql_result(field_result, return_type, unwrapped_return_type, is_nn, is_list, all_next_objects, all_next_results, is_from_array) # rubocop:disable Metrics/ParameterLists
          if field_result.nil?
            if is_nn
              @runner.add_non_null_error(@parent_type, @field_definition, @ast_node, is_from_array, path)
            else
              nil
            end
          elsif is_list
            if is_nn
              return_type = return_type.of_type
            end
            inner_type = return_type.of_type
            inner_type_nn = inner_type.non_null?
            inner_type_l = inner_type.list?
            field_result.map do |inner_f_r|
              build_graphql_result(inner_f_r, inner_type, unwrapped_return_type, inner_type_nn, inner_type_l, all_next_objects, all_next_results, true)
            end
          else
            obj_type, _ignored_value = unwrapped_return_type.kind.abstract? ? @runner.schema.resolve_type(unwrapped_return_type, field_result, @runner.context) : unwrapped_return_type
            if @runner.resolves_lazies # TODO extract this
              obj_type, _ignored_value = @runner.schema.sync_lazy(obj_type)
            end

            # TODO extract this vv
            is_auth = obj_type.authorized?(field_result, @runner.context)
            if @runner.resolves_lazies
              is_auth = @runner.schema.sync_lazy(is_auth)
            end

            if is_auth
              next_result_h = {}
              all_next_results << next_result_h
              all_next_objects << field_result
              @runner.runtime_types_at_result[next_result_h] = obj_type
              @runner.static_types_at_result[next_result_h] = unwrapped_return_type
              next_result_h
            elsif is_nn
              @runner.add_non_null_error(@parent_type, @field_definition, @ast_node, is_from_array, path)
            else
              nil
            end
          end
        end
      end

      class RawValueFieldResolveStep < FieldResolveStep
        def build_graphql_result(field_result, return_type, return_result_type, is_nn, is_list, all_next_objects, all_next_results, is_from_array) # rubocop:disable Metrics/ParameterLists
          if field_result.is_a?(Interpreter::RawValue)
            field_result.resolve
          else
            super
          end
        end
      end
    end
  end
end
