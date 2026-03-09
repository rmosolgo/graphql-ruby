# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
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
          @all_next_objects = nil
          @all_next_results = nil
          @static_type = nil
          @next_selections = nil
          @object_is_authorized = nil
          @finish_extension_idx = nil
          @was_scoped = nil
          @pending_steps = nil
        end

        attr_reader :ast_node, :key, :parent_type, :selections_step, :runner,
          :field_definition, :object_is_authorized, :was_scoped, :field_results

        attr_accessor :pending_steps, :arguments

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
              coerce_argument_value(args_hash, arg_defn, value)
            end
          else
            ast_arguments_or_hash.each { |arg_node|
              arg_defn = arg_defns[arg_node.name]
              coerce_argument_value(args_hash, arg_defn, arg_node.value)
            }
          end
          # TODO refactor the loop above into this one
          arg_defns.each do |arg_graphql_name, arg_defn|
            if arg_defn.default_value? && !args_hash.key?(arg_defn.keyword)
              coerce_argument_value(args_hash, arg_defn, arg_defn.default_value)
            end
          end

          args_hash
        end

        def coerce_argument_value(arguments, arg_defn, arg_value, target_keyword: arg_defn.keyword, as_type: nil)
          arg_t = as_type || arg_defn.type
          if arg_t.non_null?
            arg_t = arg_t.of_type
          end

          arg_value = if arg_value.is_a?(Language::Nodes::VariableIdentifier)
            vars = @selections_step.query.variables
            if vars.key?(arg_value.name)
              vars[arg_value.name]
            elsif vars.key?(arg_value.name.to_sym)
              vars[arg_value.name.to_sym]
            else
              return # not present
            end
          elsif arg_value.is_a?(Language::Nodes::NullValue)
            nil
          elsif arg_value.is_a?(Language::Nodes::Enum)
            arg_value.name
          elsif arg_value.is_a?(Language::Nodes::InputObject)
            arg_value.arguments # rubocop:disable Development/ContextIsPassedCop
          else
            arg_value
          end

          ctx = @selections_step.query.context
          arg_value = if arg_t.list?
            if arg_value.nil?
              arg_value
            else
              arg_value = Array(arg_value)
              inner_t = arg_t.of_type
              result = Array.new(arg_value.size)
              arg_value.each_with_index { |v, i| coerce_argument_value(result, arg_defn, v, target_keyword: i, as_type: inner_t) }
              result
            end
          elsif arg_t.kind.leaf?
            begin
              arg_t.coerce_input(arg_value, ctx)
            rescue GraphQL::UnauthorizedEnumValueError => enum_err
              begin
                @runner.schema.unauthorized_object(enum_err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
          elsif arg_t.kind.input_object?
            input_obj_args = coerce_arguments(arg_t, arg_value)
            arg_t.new(nil, ruby_kwargs: input_obj_args, context: @selections_step.query.context, defaults_used: nil)
          else
            raise "Unsupported argument value: #{arg_t.to_type_signature} / #{arg_value.class} (#{arg_value.inspect})"
          end

          if as_type.nil? # only on root arguments, not list elements
            arg_value = begin
              begin
                arg_defn.prepare_value(nil, arg_value, context: ctx)
              rescue StandardError => err
                @runner.schema.handle_or_reraise(ctx, err)
              end
            rescue GraphQL::ExecutionError => exec_err
              exec_err
            end
          end

          if arg_value.is_a?(GraphQL::Error)
            @arguments = arg_value
          elsif arg_defn.loads && as_type.nil? && !arg_value.nil?
            # This is for legacy compat:
            load_receiver = if (r = @field_definition.resolver)
              r.new(field: @field_definition, context: @selections_step.query.context, object: nil)
            else
              @field_definition
            end
            @pending_steps ||= []
            if arg_t.list?
              results = Array.new(arg_value.size, nil)
              arguments[arg_defn.keyword] = results
              arg_value.each_with_index do |inner_v, idx|
                loads_step = LoadArgumentStep.new(
                  field_resolve_step: self,
                  load_receiver: load_receiver,
                  argument_value: inner_v,
                  argument_definition: arg_defn,
                  arguments: results,
                  argument_key: idx,
                )
                @pending_steps.push(loads_step)
                @runner.add_step(loads_step)
              end
            else
              loads_step = LoadArgumentStep.new(
                field_resolve_step: self,
                load_receiver: load_receiver,
                argument_value: arg_value,
                argument_definition: arg_defn,
                arguments: arguments,
                argument_key: arg_defn.keyword,
              )
              @pending_steps.push(loads_step)
              @runner.add_step(loads_step)
            end
          else
            arguments[target_keyword] = arg_value
          end
          nil
        end

        # Implement that Lazy API
        def value
          query = @selections_step.query
          query.current_trace.begin_execute_field(@field_definition, @arguments, @field_results, query)
          @field_results = sync(@field_results)
          query.current_trace.end_execute_field(@field_definition, @arguments, @field_results, query, @field_results)
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
        rescue StandardError => stderr
          begin
            @selections_step.query.handle_or_reraise(stderr)
          rescue GraphQL::ExecutionError => ex_err
            ex_err
          end
        end

        def call
          if @enqueued_authorization
            enqueue_next_steps
          elsif @finish_extension_idx
            finish_extensions
          elsif @field_results
            build_results
          elsif @arguments
            execute_field
          else
            build_arguments
          end
        rescue StandardError => err
          if @field_definition && !err.message.start_with?("Resolving ")
            # TODO remove this check ^^^^^^ when NullDataloader isn't recursive
            raise err, "Resolving #{@field_definition.path}: #{err.message}", err.backtrace
          else
            raise
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

        def build_arguments
          query = @selections_step.query
          field_name = @ast_node.name
          @field_definition = query.get_field(@parent_type, field_name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
          if field_name == "__typename"
            # TODO handle custom introspection
            @field_results = Array.new(@selections_step.objects.size, @parent_type.graphql_name)
            @object_is_authorized = AlwaysAuthorized
            build_results
            return
          end

          arguments = coerce_arguments(@field_definition, @ast_node.arguments) # rubocop:disable Development/ContextIsPassedCop
          @arguments ||= arguments # may have already been set to an error

          if @pending_steps.nil? || @pending_steps.size == 0
            execute_field
          end
        end

        def execute_field
          objects = @selections_step.objects
          # TODO not as good because only one error?
          if @arguments.is_a?(GraphQL::Error)
            @field_results = Array.new(objects.size, @arguments)
            @object_is_authorized = AlwaysAuthorized
            build_results
            return
          end

          query = @selections_step.query
          ctx = query.context
          if (v = @field_definition.validators).any?  # rubocop:disable Development/NoneWithoutBlockCop
            begin
              Schema::Validator.validate!(v, nil, ctx, @arguments)
            rescue GraphQL::RuntimeError => err
              @field_results = Array.new(objects.size, err)
              @object_is_authorized = AlwaysAuthorized
              build_results
              return
            end
          end

          @field_definition.extras.each do |extra|
            case extra
            when :lookahead
              if @arguments.frozen?
                @arguments = @arguments.dup
              end
              @arguments[:lookahead] = Execution::Lookahead.new(
                query: query,
                ast_nodes: ast_nodes,
                field: @field_definition,
              )
            when :ast_node
              if @arguments.frozen?
                @arguments = @arguments.dup
              end
              @arguments[:ast_node] = ast_node
            else
              raise ArgumentError, "This `extra` isn't supported yet: #{extra.inspect}. Open an issue on GraphQL-Ruby to add compatibility for it."
            end
          end

          if @field_definition.dynamic_introspection
            # TODO break this backwards compat somehow?
            objects = @selections_step.graphql_objects
          end

          if @runner.authorization && @runner.authorizes?(@field_definition, ctx)
            authorized_objects = []
            @object_is_authorized = objects.map { |o|
              is_authed = @field_definition.authorized?(o, @arguments, ctx)
              if is_authed
                authorized_objects << o
              end
              is_authed
            }
            if authorized_objects.size == 0
              return
            end
          else
            authorized_objects = objects
            @object_is_authorized = AlwaysAuthorized
          end

          if @parent_type.default_relay? && authorized_objects.all? { |o| o.respond_to?(:was_authorized_by_scope_items?) && o.was_authorized_by_scope_items? }
            @was_scoped = true
          end

          query.current_trace.begin_execute_field(@field_definition, @arguments, authorized_objects, query)
          has_extensions = @field_definition.extensions.size > 0
          if has_extensions
            @extended = GraphQL::Schema::Field::ExtendedState.new(@arguments, authorized_objects)
            @field_results = @field_definition.run_next_extensions_before_resolve(authorized_objects, @arguments, ctx, @extended) do |objs, args|
              if (added_extras = @extended.added_extras)
                args = args.dup
                added_extras.each { |e| args.delete(e) }
              end
              resolve_batch(objs, ctx, args)
            end
            @finish_extension_idx = 0
          else
            @field_results = resolve_batch(authorized_objects, ctx, @arguments)
          end

          query.current_trace.end_execute_field(@field_definition, @arguments, authorized_objects, query, @field_results)

          if any_lazy_results?
            @runner.dataloader.lazy_at_depth(path.size, self)
          elsif has_extensions
            finish_extensions
          elsif @pending_steps.nil? || @pending_steps.empty?
            build_results
          end
        end

        def any_lazy_results?
          lazies = false
          if @runner.resolves_lazies # TODO extract this
            @field_results.each do |field_result|
              if @runner.lazy?(field_result)
                lazies = true
                break
              elsif field_result.is_a?(Array)
                field_result.each do |inner_fr|
                  if @runner.lazy?(inner_fr)
                    break lazies = true
                  end
                end
                if lazies
                  break
                end
              end
            end
          end
          lazies
        end

        def finish_extensions
          ctx = @selections_step.query.context
          memos = @extended.memos || EmptyObjects::EMPTY_HASH
          while ext = @field_definition.extensions[@finish_extension_idx]
            # These two are hardcoded here because of how they need to interact with runtime metadata.
            # It would probably be better
            case ext
            when Schema::Field::ConnectionExtension
              conns = ctx.schema.connections
              @field_results = @field_results.map.each_with_index do |value, idx|
                object = @extended.object[idx]
                conn = conns.populate_connection(@field_definition, object, value, @arguments, ctx)
                if conn
                  conn.was_authorized_by_scope_items = @was_scoped
                end
                conn
              end
            when Schema::Field::ScopeExtension
              if @was_scoped.nil?
                if (rt = @field_definition.type.unwrap).respond_to?(:scope_items)
                  @was_scoped = true
                  @field_results = @field_results.map { |v| v.nil? ? v : rt.scope_items(v, ctx) }
                else
                  @was_scoped = false
                end
              end
            else
              memo = memos[@finish_extension_idx]
              @field_results = ext.after_resolve_next(objects: @extended.object, arguments: @extended.arguments, context: ctx, values: @field_results, memo: memo) # rubocop:disable Development/ContextIsPassedCop
            end
            @finish_extension_idx += 1
            if any_lazy_results?
              @runner.dataloader.lazy_at_depth(path.size, self)
              return
            end
          end

          @finish_extension_idx = nil
          build_results
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
            i = 0
            s = results.size
            while i < s do
              result_h = results[i]
              if @object_is_authorized[i]
                result = @field_results[field_result_idx]
                field_result_idx += 1
              else
                result = nil
              end
              i += 1
              build_graphql_result(result_h, @key, result, return_type, is_non_null, is_list, false)
            end
            @enqueued_authorization = true

            if @pending_steps.nil? || @pending_steps.size == 0
              enqueue_next_steps
            else
              # Do nothing -- it will enqueue itself later
            end
          else
            ctx = @selections_step.query.context
            results = @selections_step.results
            field_result_idx = 0
            i = 0
            s = results.size
            while i < s do
              result_h = results[i]
              if @object_is_authorized[i]
                field_result = @field_results[field_result_idx]
                field_result_idx += 1
              else
                field_result = nil
              end
              i += 1
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

              @all_next_objects.each_with_index do |next_object, i|
                result = @all_next_results[i]
                if (object_type = @runner.runtime_type_at[result])
                  # OK
                else
                  object_type = @runner.resolve_type(@static_type, next_object, @selections_step.query)
                  @runner.runtime_type_at[result] = object_type
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

        def authorized_finished(step)
          @pending_steps.delete(step)
          if @enqueued_authorization && @pending_steps.size == 0
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
            i = 0
            s = field_result.size
            while i < s
              inner_f_r = field_result[i]
              build_graphql_result(list_result, i, inner_f_r, inner_type, inner_type_nn, inner_type_l, true)
              i += 1
            end
          elsif @runner.resolves_lazies || (@runner.authorization && (@static_type.kind.object? ? @runner.authorizes?(@static_type, @selections_step.query.context) : (
                (runtime_type = (@runner.runtime_type_at[graphql_result] = @runner.resolve_type(@static_type, field_result, @selections_step.query))
                ) && @runner.authorizes?(runtime_type, @selections_step.query.context)
              )))
            obj_step = PrepareObjectStep.new(
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
            )
            ps = @pending_steps ||= []
            ps << obj_step
            @runner.add_step(obj_step)
          else
            next_result_h = {}
            @all_next_results << next_result_h
            @all_next_objects << field_result
            @runner.static_type_at[next_result_h] = @static_type
            graphql_result[key] = next_result_h
          end
        end

        def resolve_batch(objects, context, args_hash)
          method_receiver = @field_definition.dynamic_introspection ? @field_definition.owner : @parent_type
          case @field_definition.execution_next_mode
          when :resolve_batch
            if args_hash.empty?
              method_receiver.public_send(@field_definition.execution_next_mode_key, objects, context)
            else
              method_receiver.public_send(@field_definition.execution_next_mode_key, objects, context, **args_hash)
            end
          when :resolve_static
            result = if args_hash.empty?
              method_receiver.public_send(@field_definition.execution_next_mode_key, context)
            else
              method_receiver.public_send(@field_definition.execution_next_mode_key, context, **args_hash)
            end
            Array.new(objects.size, result)
          when :resolve_each
            if args_hash.empty?
              objects.map { |o| method_receiver.public_send(@field_definition.execution_next_mode_key, o, context) }
            else
              objects.map { |o| method_receiver.public_send(@field_definition.execution_next_mode_key, o, context, **args_hash) }
            end
          when :hash_key
            objects.map { |o| o[@field_definition.execution_next_mode_key] }
          when :direct_send
            if args_hash.empty?
              objects.map { |o| o.public_send(@field_definition.execution_next_mode_key) }
            else
              objects.map { |o| o.public_send(@field_definition.execution_next_mode_key, **args_hash) }
            end
          when :dig
            objects.map { |o| o.dig(*@field_definition.execution_next_mode_key) }
          when :resolver_class
            results = Array.new(objects.size, nil)
            ps = @pending_steps ||= []
            objects.each_with_index do |o, idx|
              resolver_inst = @field_definition.resolver.new(object: o, context: context, field: @field_definition)
              ps << resolver_inst
              resolver_inst.field_resolve_step = self
              resolver_inst.prepared_arguments = args_hash
              resolver_inst.exec_result = results
              resolver_inst.exec_index = idx
              @runner.add_step(resolver_inst)
              resolver_inst
            end
            results
          when :resolve_legacy_instance_method
            @selections_step.graphql_objects.map do |obj_inst|
              if @field_definition.dynamic_introspection
                obj_inst = @owner.wrap(obj_inst, context)
              end
              if args_hash.empty?
                obj_inst.public_send(@field_definition.execution_next_mode_key)
              else
                obj_inst.public_send(@field_definition.execution_next_mode_key, **args_hash)
              end
            end
          else
            raise "Batching execution for #{path} not implemented (execution_next_mode: #{@execution_next_mode.inspect}); provide `resolve_static:`, `resolve_batch:`, `hash_key:`, `method:`, or use a compatibility plug-in"
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
