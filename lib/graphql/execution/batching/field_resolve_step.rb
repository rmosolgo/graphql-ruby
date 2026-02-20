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
          @runner = runner
          @field_definition = nil
          @arguments = nil
          @field_results = nil
          @path = nil
          @enqueued_authorization = false
          @pending_authorize_steps_count = 0
          @all_next_objects = nil
          @all_next_results = nil
          @static_type = nil
          @next_selections = nil
          @object_is_authorized = nil
        end

        attr_reader :ast_node, :key, :parent_type, :selections_step, :runner, :field_definition, :object_is_authorized, :arguments

        def path
          @path ||= [*@selections_step.path, @key].freeze
        end

        def ast_nodes
          @ast_nodes ||= [@ast_node]
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
          arg_defns = argument_owner.arguments(@selections_step.query.context)
          if arg_defns.empty?
            return EmptyObjects::EMPTY_HASH
          end
          args_hash = {}
          if ast_arguments_or_hash.is_a?(Hash)
            ast_arguments_or_hash.each do |key, value|
              key_s = nil
              arg_defn = arg_defns.each_value.find { |a|
                a.keyword == key || a.graphql_name == (key_s ||= String(key))
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
            vars = @selections_step.query.variables
            arg_value = if vars.key?(arg_value.name)
              vars[arg_value.name]
            elsif vars.key?(arg_value.name.to_sym)
              vars[arg_value.name.to_sym]
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
            begin
              ctx = @selections_step.query.context
              arg_t.coerce_input(arg_value, ctx)
            rescue GraphQL::UnauthorizedEnumValueError => enum_err
              begin
                @runner.schema.unauthorized_object(enum_err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
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
        rescue GraphQL::UnauthorizedError => auth_err
          @runner.schema.unauthorized_object(auth_err)
        rescue GraphQL::ExecutionError => err
          err
        end

        def call
          if @enqueued_authorization && @pending_authorize_steps_count == 0
            enqueue_next_steps
          elsif @field_results
            build_results
          else
            execute_field
          end
        end

        def add_graphql_error(err)
          err.path = path
          err.ast_nodes = ast_nodes
          @selections_step.query.context.add_error(err)
          err
        end

        module AlwaysAuthorized
          def self.[](_key)
            true
          end
        end

        def execute_field
          field_name = @ast_node.name
          @field_definition = @selections_step.query.get_field(@parent_type, field_name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
          objects = @selections_step.objects
          if field_name == "__typename"
            # TODO handle custom introspection
            @field_results = Array.new(objects.size, @parent_type.graphql_name)
            @object_is_authorized = AlwaysAuthorized
            build_results
            return
          end

          @arguments = coerce_arguments(@field_definition, @ast_node.arguments) # rubocop:disable Development/ContextIsPassedCop


          ctx = @selections_step.query.context

          if (@runner.authorizes.fetch(@field_definition) { @runner.authorizes[@field_definition] = @field_definition.authorizes?(ctx) })
            authorized_objects = []
            @object_is_authorized = objects.map { |o|
              is_authed = @field_definition.authorized?(o, @arguments, ctx)
              if is_authed
                authorized_objects << o
              end
              is_authed
            }
          else
            authorized_objects = objects
            @object_is_authorized = AlwaysAuthorized
          end

          @field_results = @field_definition.resolve_batch(self, authorized_objects, ctx, @arguments)

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

        def build_results
          return_type = @field_definition.type
          return_result_type = return_type.unwrap

          if return_result_type.kind.composite?
            @static_type = return_result_type
            if @ast_nodes
              @next_selections = []
              @ast_nodes.each do |ast_node|
                @next_selections.concat(ast_node.selections)
              end
            else
              @next_selections = @ast_node.selections
            end

            @all_next_objects = []
            @all_next_results = []

            is_list = return_type.list?
            is_non_null = return_type.non_null?
            results = @selections_step.results
            field_result_idx = 0
            results.each_with_index do |result_h, i|
              if @object_is_authorized[i]
                result = @field_results[field_result_idx]
                field_result_idx += 1
              else
                result = nil
              end
              build_graphql_result(result_h, @key, result, return_type, is_non_null, is_list, false)
            end
            @enqueued_authorization = true

            if @pending_authorize_steps_count == 0
              enqueue_next_steps
            else
              # Do nothing -- it will enqueue itself later
            end
          else
            results = @selections_step.results
            ctx = @selections_step.query.context
            field_result_idx = 0
            results.each_with_index do |result_h, i|
              if @object_is_authorized[i]
                field_result = @field_results[field_result_idx]
                field_result_idx += 1
              else
                field_result = nil
              end
              result_h[@key] = if field_result.nil?
                if return_type.non_null?
                  add_non_null_error(false)
                else
                  nil
                end
              elsif field_result.is_a?(GraphQL::Error)
                add_graphql_error(field_result)
              else
                # TODO `nil`s in [T!] types aren't handled
                return_type.coerce_result(field_result, ctx)
              end
            end
          end
        end

        def enqueue_next_steps
          if !@all_next_results.empty?
            @all_next_objects.compact!

            if @static_type.kind.abstract?
              next_objects_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
              next_results_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity

              ctx = nil
              @all_next_objects.each_with_index do |next_object, i|
                result = @all_next_results[i]
                if (object_type = @runner.runtime_types_at_result[result])
                  # OK
                else
                  ctx ||= @selections_step.query.context
                  object_type, _unused_new_value = @runner.schema.resolve_type(@static_type, next_object, ctx)
                end
                next_objects_by_type[object_type] << next_object
                next_results_by_type[object_type] << result
              end

              next_objects_by_type.each do |obj_type, next_objects|
                @runner.add_step(SelectionsStep.new(
                  path: path,
                  parent_type: obj_type,
                  selections: @next_selections,
                  objects: next_objects,
                  results: next_results_by_type[obj_type],
                  runner: @runner,
                  query: @selections_step.query,
                ))
              end
            else
              @runner.add_step(SelectionsStep.new(
                path: path,
                parent_type: @static_type,
                selections: @next_selections,
                objects: @all_next_objects,
                results: @all_next_results,
                runner: @runner,
                query: @selections_step.query,
              ))
            end
          end
        end

        def authorized_finished
          remaining = @pending_authorize_steps_count -= 1
          if @enqueued_authorization && remaining == 0
            @runner.add_step(self)
          end
        end

        def add_non_null_error(is_from_array)
          err = InvalidNullError.new(@parent_type, @field_definition, ast_nodes, is_from_array: is_from_array, path: path)
          @runner.schema.type_error(err, @selections_step.query.context)
        end

        private

        def build_graphql_result(graphql_result, key, field_result, return_type, is_nn, is_list, is_from_array) # rubocop:disable Metrics/ParameterLists
          if field_result.nil?
            if is_nn
              graphql_result[key] = add_non_null_error(is_from_array)
            else
              graphql_result[key] = nil
            end
          elsif field_result.is_a?(GraphQL::Error)
            graphql_result[key] = add_graphql_error(field_result)
          elsif is_list
            if is_nn
              return_type = return_type.of_type
            end
            inner_type = return_type.of_type
            inner_type_nn = inner_type.non_null?
            inner_type_l = inner_type.list?
            list_result = graphql_result[key] = []
            field_result.each_with_index do |inner_f_r, i|
              build_graphql_result(list_result, i, inner_f_r, inner_type, inner_type_nn, inner_type_l, true)
            end
          elsif @runner.resolves_lazies # Handle possible lazy resolve_type response
            @pending_authorize_steps_count += 1
            @runner.add_step(Batching::PrepareObjectStep.new(
              static_type: @static_type,
              object: field_result,
              runner: @runner,
              field_resolve_step: self,
              graphql_result: graphql_result,
              next_objects: @all_next_objects,
              next_results: @all_next_results,
              is_non_null: is_nn,
              key: key,
              is_from_array: is_from_array,
            ))
          else
            next_result_h = {}
            @all_next_results << next_result_h
            @all_next_objects << field_result
            @runner.static_types_at_result[next_result_h] = @static_type
            graphql_result[key] = next_result_h
          end
        end
      end

      class RawValueFieldResolveStep < FieldResolveStep
        def build_graphql_result(graphql_result, key, field_result, return_type, is_nn, is_list, is_from_array) # rubocop:disable Metrics/ParameterLists
          if field_result.is_a?(Interpreter::RawValue)
            graphql_result[key] = field_result.resolve
          else
            super
          end
        end
      end
    end
  end
end
