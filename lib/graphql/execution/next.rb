# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
      def self.run(schema:, query_string: nil, document: nil, context: {}, validate: true, variables: {}, root_object: nil)
        document ||= GraphQL.parse(query_string)
        if validate
          validation_errors = schema.validate(document, context: context)
          if !validation_errors.empty?
            return {
              "errors" => validation_errors.map(&:to_h)
            }
          end
        end

        runner = Runner.new(schema, document, context, variables, root_object)
        runner.execute
      end

      class Runner
        def initialize(schema, document, context, variables, root_object)
          @schema = schema
          @document = document
          @query = GraphQL::Query.new(schema, document: document, context: context, variables: variables, root_value: root_object)
          @context = @query.context
          @variables = variables
          @root_object = root_object
          @path = @context[:current_path_next] = []
          @steps_queue = []
          @data = {}
          @runtime_types_at_result = {}.compare_by_identity
          @selected_operation = nil
          @root_type = nil
          @dataloader = @context[:dataloader] ||= schema.dataloader_class.new
        end

        def add_step(step)
          @dataloader.append_job(step)
        end

        attr_reader :steps_queue, :schema, :context, :variables, :runtime_types_at_result

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
            {
              "errors" => @context.errors.map(&:to_h),
              "data" => data
            }
          end

          GraphQL::Query::Result.new(query: @query, values: result)
        end

        def gather_selections(type_defn, ast_selections, selections_step, into:)
          ast_selections.each do |ast_selection|
            next if !directives_include?(ast_selection)
            case ast_selection
            when GraphQL::Language::Nodes::Field
              key = ast_selection.alias || ast_selection.name
              step = into[key] ||= FieldResolveStep.new(
                selections_step: selections_step,
                key: key,
                parent_type: type_defn,
                runner: self,
              )
              step.append_selection(ast_selection)
            when GraphQL::Language::Nodes::InlineFragment
              type_condition = ast_selection.type.name
              if type_condition_applies?(type_defn, type_condition)
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
              runtime_type_at_result = @runtime_types_at_result[result_h]
              if type_condition_applies?(runtime_type_at_result, ast_selection.type.name)
                result_h = check_object_result(result_h, static_type, ast_selection.selections, current_exec_path, current_result_path, paths_to_check)
              end
            when Language::Nodes::FragmentSpread
              fragment_defn = @document.definitions.find { |defn| defn.is_a?(Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
              runtime_type_at_result = @runtime_types_at_result[result_h]
              if type_condition_applies?(runtime_type_at_result, fragment_defn.type.name)
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

        class FieldResolveStep
          def initialize(parent_type:, runner:, key:, selections_step:)
            @selection_step = selections_step
            @key = key
            @parent_type = parent_type
            @ast_node = @ast_nodes = nil
            @objects = nil
            @results = nil
            @runner = runner
            @path = nil
          end

          attr_writer :objects, :results

          attr_reader :ast_node, :ast_nodes, :key, :parent_type

          def path
            @path ||= [*@selection_step.path, @key].freeze
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
                args_hash[arg_defn.keyword] = arg_value
              end
            else
              ast_arguments_or_hash.each { |arg_node|
                arg_defn = arg_defns[arg_node.name]
                arg_value = coerce_argument_value(arg_defn.type, arg_node.value)
                arg_key = arg_defn.keyword
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
              arg_value = Array(arg_value)
              inner_t = arg_t.of_type
              arg_value.map { |v| coerce_argument_value(inner_t, v) }
            elsif arg_t.kind.leaf?
              arg_t.coerce_input(arg_value, @runner.context)
            elsif arg_t.kind.input_object?
              coerce_arguments(arg_t, arg_value)
            else
              raise "Unsupported argument value: #{arg_t.to_type_signature} / #{arg_value.class} (#{arg_value.inspect})"
            end
          end

          def call
            field_defn = @runner.schema.get_field(@parent_type, @ast_node.name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
            result_key = @ast_node.alias || @ast_node.name

            arguments = coerce_arguments(field_defn, @ast_node.arguments) # rubocop:disable Development/ContextIsPassedCop

            field_results = if arguments.empty?
              field_defn.resolve_all(self, @objects, @runner.context)
            else
              field_defn.resolve_all(self, @objects, @runner.context, **arguments)
            end

            return_type = field_defn.type
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
              field_results.each_with_index do |result, i|
                result_h = @results[i]
                result_h[result_key] = build_graphql_result(field_defn, result, return_type, is_non_null, is_list, all_next_objects, all_next_results, false)
              end

              if !all_next_results.empty?
                all_next_objects.compact!

                if return_result_type.kind.abstract?
                  next_objects_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
                  next_results_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
                  all_next_objects.each_with_index do |next_object, i|
                    object_type, _ignored_new_value = @runner.schema.resolve_type(return_result_type, next_object, @runner.context)
                    next_objects_by_type[object_type] << next_object
                    next_results_by_type[object_type] << all_next_results[i]
                  end

                  next_objects_by_type.each do |obj_type, next_objects|
                    @runner.add_step(SelectionsStep.new(
                      path: path, # TODO pass self here?
                      parent_type: obj_type,
                      selections: next_selections,
                      objects: next_objects,
                      results: next_results_by_type[obj_type],
                      runner: @runner,
                    ))
                  end
                else
                  @runner.add_step(SelectionsStep.new(
                    path: path, # TODO pass self here?
                    parent_type: return_result_type,
                    selections: next_selections,
                    objects: all_next_objects,
                    results: all_next_results,
                    runner: @runner,
                  ))
                end
              end
            else
              field_results.each_with_index do |result, i|
                result_h = @results[i] || raise("Invariant: no result object at index #{i} for #{@parent_type.to_type_signature}.#{ast_node.name} (result: #{result.inspect})")
                result_h[result_key] = if result.nil?
                  if return_type.non_null?
                    @runner.add_non_null_error(@parent_type, field_defn, @ast_node, false, path)
                  else
                    nil
                  end
                else
                  return_type.coerce_result(result, @runner.context)
                end
              end
            end
          end

          private

          def build_graphql_result(field_defn, field_result, return_type, is_nn, is_list, all_next_objects, all_next_results, is_from_array) # rubocop:disable Metrics/ParameterLists
            if field_result.nil?
              if is_nn
                @runner.add_non_null_error(@parent_type, field_defn, @ast_node, is_from_array, path)
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
                build_graphql_result(field_defn, inner_f_r, inner_type, inner_type_nn, inner_type_l, all_next_objects, all_next_results, true)
              end
            else
              next_result_h = {}
              @runner.runtime_types_at_result[next_result_h] = return_type.unwrap
              all_next_results << next_result_h
              all_next_objects << field_result
              next_result_h
            end
          end
        end

        class SelectionsStep
          def initialize(parent_type:, selections:, objects:, results:, runner:, path:)
            @path = path
            @parent_type = parent_type
            @selections = selections
            @objects = objects
            @results = results
            @runner = runner
          end

          attr_reader :path

          def call
            grouped_selections = {}
            @runner.gather_selections(@parent_type, @selections, self, into: grouped_selections)
            grouped_selections.each_value do |frs|
              frs.objects = @objects
              frs.results = @results
              # TODO order result hashes correctly.
              # I don't think this implementation will work forever
              @results.each { |r| r[frs.key] = nil }
              @runner.add_step(frs)
            end
          end
        end
      end

      module FieldCompatibility
        def resolve_all_load_arguments(arguments, argument_owner, context)
          arg_defns = context.types.arguments(argument_owner)
          arg_defns.each do |arg_defn|
            if arg_defn.loads
              id = arguments.delete(arg_defn.keyword)
              if id
                value = context.schema.object_from_id(id, context)
                arguments[arg_defn.keyword] = value
              end
            elsif (input_type = arg_defn.type.unwrap).kind.input_object? # TODO lists
              value = arguments[arg_defn.keyword]
              resolve_all_load_arguments(value, input_type, context)
            end
          end
        end

        def resolve_all(frs, objects, context, **kwargs)
          resolve_all_load_arguments(kwargs, self, context)
          resolve_all_m = :"all_#{@method_sym}"
          if extras.include?(:lookahead)
            kwargs[:lookahead] = Execution::Lookahead.new(
              query: context.query,
              ast_nodes: frs.ast_nodes || Array(frs.ast_node),
              field: self,
            )
          end
          if @owner.respond_to?(resolve_all_m)
            if kwargs.empty?
              @owner.public_send(resolve_all_m, objects, context)
            else
              @owner.public_send(resolve_all_m, objects, context, **kwargs)
            end
          # elsif dynamic_introspection
          #   objects.map { |o| o.public_send(@method_sym) }
          elsif @owner.method_defined?(@method_sym)
            # Terrible perf but might work
            # I think the viable possible future is for `frs`
            # to maintain a list of object instances and use them here
            objects.map { |o|
              obj_inst = frs.parent_type.scoped_new(o, context)
              if dynamic_introspection
                obj_inst = @owner.scoped_new(obj_inst, context)
              end
              if kwargs.empty?
                obj_inst.public_send(@method_sym)
              else
                obj_inst.public_send(@method_sym, **kwargs)
              end
            }
          elsif @resolver_class
            objects.map { |o|
              resolver_inst = @resolver_class.new(object: o, context: context, field: self)
              if kwargs.empty?
                resolver_inst.public_send(@resolver_class.resolver_method)
              else
                resolver_inst.public_send(@resolver_class.resolver_method, **kwargs)
              end
            }
          elsif objects.first.is_a?(Hash)
            objects.map { |o| o[method_sym] || o[graphql_name] }
          elsif objects.first.is_a?(Interpreter::RawValue)
            objects
          else
            objects.map { |o| o.public_send(@method_sym) }
          end
        end
      end

      GraphQL::Schema::Field.include(FieldCompatibility)
    end
  end
end
