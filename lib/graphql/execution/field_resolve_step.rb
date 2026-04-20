# frozen_string_literal: true
module GraphQL
  module Execution
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
        @post_processors = @directive_finalizers = nil
      end

      attr_reader :ast_node, :key, :parent_type, :selections_step, :runner,
        :field_definition, :object_is_authorized, :was_scoped, :field_results

      attr_accessor :pending_steps, :arguments, :static_type

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

      def coerce_arguments(argument_owner, ast_arguments_or_hash, run_loads = true)
        arg_defns = @selections_step.query.types.arguments(argument_owner)
        if arg_defns.empty?
          return EmptyObjects::EMPTY_HASH
        end
        args_hash = {}

        if ast_arguments_or_hash.nil? # This can happen with `.trigger`
          return args_hash
        end

        arg_inputs_are_h = ast_arguments_or_hash.is_a?(Hash)

        arg_defns.each do |arg_defn|
          arg_value = nil
          was_found = false
          if arg_inputs_are_h
            ast_arguments_or_hash.each do |key, value|
              if key == arg_defn.keyword || key.to_s == arg_defn.graphql_name
                arg_value = value
                was_found = true
                break
              end
            end
          else
            ast_arguments_or_hash.each do |arg_node|
              if arg_node.name == arg_defn.graphql_name
                arg_value = arg_node.value
                was_found = true
                break
              end
            end
          end

          if arg_value.is_a?(Language::Nodes::VariableIdentifier)
            vars = @selections_step.query.variables
            arg_value = if vars.key?(arg_value.name)
              vars[arg_value.name]
            elsif vars.key?(arg_value.name.to_sym)
              vars[arg_value.name.to_sym]
            else
              was_found = false
              nil
            end
          end

          if !was_found && arg_defn.default_value?
            was_found = true
            arg_value = arg_defn.default_value
          end

          if was_found
            coerce_argument_value(args_hash, arg_defn, arg_value, run_loads)
          end
        end

        args_hash
      end

      def coerce_argument_value(arguments, arg_defn, arg_value, run_loads, target_keyword: run_loads ? arg_defn.keyword : arg_defn.graphql_name, as_type: nil)
        arg_t = as_type || arg_defn.type
        if arg_t.non_null?
          arg_t = arg_t.of_type
        end

        if arg_value.is_a?(Language::Nodes::VariableIdentifier)
          vars = @selections_step.query.variables
          arg_value = if vars.key?(arg_value.name)
            vars[arg_value.name]
          elsif vars.key?(arg_value.name.to_sym)
            vars[arg_value.name.to_sym]
          else
            nil
          end
        end

        if arg_value.is_a?(Language::Nodes::NullValue)
          arg_value = nil
        elsif arg_value.is_a?(Language::Nodes::Enum)
          arg_value = arg_value.name
        end

        ctx = @selections_step.query.context
        arg_value = if arg_t.list?
          if arg_value.nil?
            arg_value
          else
            arg_value = Array(arg_value)
            inner_t = arg_t.of_type
            result = Array.new(arg_value.size)
            arg_value.each_with_index { |v, i| coerce_argument_value(result, arg_defn, v, run_loads, target_keyword: i, as_type: inner_t) }
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
          input_obj_vals = arg_value.is_a?(Language::Nodes::InputObject) ? arg_value.arguments : arg_value # rubocop:disable Development/ContextIsPassedCop
          input_obj_args = coerce_arguments(arg_t, input_obj_vals)
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

        if arg_value.is_a?(GraphQL::RuntimeError)
          @arguments = arg_value
        elsif run_loads && arg_defn.loads && as_type.nil? && !arg_value.nil?
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
        sync(@field_results)
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
        @field_definition = query.types.field(@parent_type, field_name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
        arguments = coerce_arguments(@field_definition, @ast_node.arguments) # rubocop:disable Development/ContextIsPassedCop
        @arguments ||= arguments # may have already been set to an error

        if (@pending_steps.nil? || @pending_steps.size == 0) &&
            @field_results.nil? # Make sure the arguments flow didn't already call through
          execute_field
        end
      end

      def execute_field
        objects = @selections_step.objects
        # TODO not as good because only one error?
        if @arguments.is_a?(GraphQL::RuntimeError)
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
            else
              begin
                err = GraphQL::UnauthorizedFieldError.new(object: o, type: @parent_type, context: ctx, field: @field_definition)
                authorized_objects << query.schema.unauthorized_object(err)
                is_authed = true
              rescue GraphQL::ExecutionError => exec_err
                add_graphql_error(exec_err)
              end
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

        if @runner.uses_runtime_directives
          if @ast_nodes.nil? || @ast_nodes.size == 1
            directives = if !@ast_node.directives.empty?
              @ast_node.directives
            else
              nil
            end
          else
            directives = nil
            @ast_nodes.each do |n|
              if (d = n.directives).any? # rubocop:disable Development/NoneWithoutBlockCop
                directives ||= []
                directives.concat(d)
              end
            end
          end

          if directives
            directives.each do |dir_node|
              if (dir_defn = @runner.runtime_directives[dir_node.name])
                # TODO: `coerce_arguments` modifies self, assuming it's field arguments. Extract to pure function for use
                # here and with fragments.
                dir_args = coerce_arguments(dir_defn, dir_node.arguments, false) # rubocop:disable Development/ContextIsPassedCop
                result = dir_defn.resolve_field(ast_nodes, @parent_type, field_definition, authorized_objects, dir_args, ctx)
                if !result.nil?
                  if result.is_a?(Finalizer)
                    result.path = path
                    @directive_finalizers ||= []
                    @directive_finalizers << result
                  end

                  if result.is_a?(PostProcessor)
                    @post_processors ||= []
                    @post_processors << result
                  end

                  if result.is_a?(HaltExecution)
                    @directive_finalizers&.each { |f|
                      @selections_step.results.each { |r|  @runner.add_finalizer(query, r, key, f) }
                    }
                    return
                  end
                end
              end
            end
          end
        end

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
            @field_results.map!.each_with_index do |value, idx|
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
                @field_results.map! { |v| v.nil? ? v : rt.scope_items(v, ctx) }
              else
                @was_scoped = false
              end
            end
          else
            memo = memos[@finish_extension_idx]
            @field_results = ext.after_resolve(objects: @extended.object, arguments: @extended.arguments, context: ctx, values: @field_results, memo: memo) # rubocop:disable Development/ContextIsPassedCop
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

        @post_processors&.each do |post_processor|
          @field_results = post_processor.after_resolve(@field_results)
        end

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
            finish_leaf_result(result_h, @key, field_result, return_type, ctx)
          end
        end
      end

      def finish_leaf_result(result_h, key, field_result, return_type, ctx)
        final_field_result = if field_result.nil?
          if return_type.non_null?
            add_non_null_error(false)
          else
            nil
          end
        elsif field_result.is_a?(Finalizer)
          if field_result.is_a?(GraphQL::RuntimeError)
            add_graphql_error(field_result)
          else
            field_result.path = path
            @runner.add_finalizer(ctx.query, result_h, key, field_result)
          end
        else
          # TODO `nil`s in [T!] types aren't handled
          return_type.coerce_result(field_result, ctx)
        end

        @directive_finalizers&.each { |f| @runner.add_finalizer(ctx.query, result_h, key, f) }
        result_h[@key] = final_field_result
      end

      def enqueue_next_steps
        if !@all_next_results.empty?
          @all_next_objects.compact!

          query = @selections_step.query
          ctx = query.context
          if @static_type.kind.abstract?
            next_objects_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
            next_results_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity

            @all_next_objects.each_with_index do |next_object, i|
              result = @all_next_results[i]
              if (object_type = @runner.runtime_type_at[result])
                # OK
              else
                object_type = @runner.resolve_type(@static_type, next_object, query)
                @runner.runtime_type_at[result] = object_type
              end
              next_objects_by_type[object_type] << next_object
              next_results_by_type[object_type] << result
            end

            next_objects_by_type.each do |obj_type, next_objects|
              query.current_trace.objects(obj_type, next_objects, ctx)
              @runner.add_step(SelectionsStep.new(
                path: path,
                parent_type: obj_type,
                selections: @next_selections,
                objects: next_objects,
                results: next_results_by_type[obj_type],
                runner: @runner,
                query: query,
              ))
            end
          else
            query.current_trace.objects(@static_type, @all_next_objects, ctx)
            @runner.add_step(SelectionsStep.new(
              path: path,
              parent_type: @static_type,
              selections: @next_selections,
              objects: @all_next_objects,
              results: @all_next_results,
              runner: @runner,
              query: query,
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
        elsif field_result.is_a?(Finalizer)
          graphql_result[key] = if field_result.is_a?(GraphQL::RuntimeError)
            add_graphql_error(field_result)
          else
            field_result.path = path
            @runner.add_finalizer(@selections_step.query, graphql_result, key, field_result)
            field_result
          end
        elsif is_list
          if is_nn
            return_type = return_type.of_type
          end
          inner_type = return_type.of_type
          inner_type_nn = inner_type.non_null?
          inner_type_l = inner_type.list?
          list_result = graphql_result[key] = []
          @directive_finalizers&.each { |f| @runner.add_finalizer(@selections_step.query, list_result, nil, f) }
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
          next_result_h = {}.compare_by_identity
          @all_next_results << next_result_h
          @directive_finalizers&.each { |f| @runner.add_finalizer(@selections_step.query, next_result_h, nil, f) }
          @all_next_objects << field_result
          @runner.static_type_at[next_result_h] = @static_type
          graphql_result[key] = next_result_h
        end
      end

      def resolve_batch(objects, context, args_hash)
        method_receiver = @field_definition.dynamic_introspection ? @field_definition.owner : @parent_type
        case @field_definition.execution_mode
        when :resolve_batch
          begin
            method_receiver.public_send(@field_definition.execution_mode_key, objects, context, **args_hash)
          rescue GraphQL::ExecutionError => exec_err
            Array.new(objects.size, exec_err)
          end
        when :resolve_static
          result = begin
            method_receiver.public_send(@field_definition.execution_mode_key, context, **args_hash)
          rescue GraphQL::ExecutionError => err
            err
          end
          Array.new(objects.size, result)
        when :resolve_each
          objects.map do |o|
            method_receiver.public_send(@field_definition.execution_mode_key, o, context, **args_hash)
          rescue GraphQL::ExecutionError => err
            err
          end
        when :hash_key
          k = @field_definition.execution_mode_key
          objects.map { |o| o[k] }
        when :direct_send
          m = @field_definition.execution_mode_key
          objects.map do |o|
            o.public_send(m, **args_hash)
          rescue GraphQL::ExecutionError => err
            err
          rescue StandardError => stderr
            begin
              @selections_step.query.handle_or_reraise(stderr)
            rescue GraphQL::ExecutionError => ex_err
              ex_err
            end
          end
        when :dig
          objects.map { |o| o.dig(*@field_definition.execution_mode_key) }
        when :dataload
          if (k = @field_definition.execution_mode_key).is_a?(Class)
            context.dataload_all(k, objects)
          elsif (source_class = k[:with])
            if (batch_args = k[:by])
              context.dataload_all(source_class, *batch_args, objects)
            else
              context.dataload_all(source_class, objects)
            end
          elsif (model = k[:model])
            value_method = k[:using]
            values = objects.map(&value_method)
            context.dataload_all_records(model, values, find_by: k[:find_by])
          elsif (assoc = k[:association])
            if assoc == true
              assoc = @field_definition.original_name
            end
            context.dataload_all_associations(objects, assoc, scope: k[:scope])
          else
            raise ArgumentError, "Unexpected `dataload: ...` configuration: #{k.inspect}"
          end
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
            obj_inst.public_send(@field_definition.execution_mode_key, **args_hash)
          rescue GraphQL::ExecutionError => exec_err
            exec_err
          end
        else
          raise "Batching execution for #{path} not implemented (execution_mode: #{@execution_mode.inspect}); provide `resolve_static:`, `resolve_batch:`, `hash_key:`, `method:`, or use a compatibility plug-in"
        end
      end
    end
  end
end
