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
        @results = nil
        @finish_extension_idx = nil
        @was_scoped = nil
        @pending_steps = nil
        @arguments_without_loads = @post_processors = @directive_finalizers = nil
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

      def value
        return nil if @selections_step.killed
        query = @selections_step.query
        set_current_field
        query.current_trace.begin_execute_field(@field_definition, @arguments, @field_results, query)
        sync(@field_results)
        query.current_trace.end_execute_field(@field_definition, @arguments, @field_results, query, @field_results)
        @runner.add_step(self)
        true
      ensure
        set_current_field(nil)
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
          @selections_step.query.handle_or_reraise(stderr, field: @field_definition, arguments: @arguments, object: nil)
        rescue GraphQL::ExecutionError => ex_err
          ex_err
        end
      end

      def call
        return nil if @selections_step.killed
        set_current_field if @field_definition

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
      ensure
        set_current_field(nil)
      end

      def add_graphql_error(result, key, err, return_type: @field_definition.type)
        err.path = path
        if err.ast_node.nil?
          err.ast_nodes = ast_nodes
        end
        errs = @runner.error_results[@selections_step.query][result] ||= {}.compare_by_identity
        if (existing_error = errs[key])
          if existing_error.is_a?(Array)
            existing_error << err
          else
            errs[key] = [existing_error, err]
          end
        else
          errs[key] = err
        end
        if !err.is_a?(GraphQL::Execution::Skip)
          field_type = return_type
          should_propagate_null = field_type.non_null?
          while (should_propagate_null == false && field_type.kind.wraps?)
            field_type = field_type.of_type
            should_propagate_null = field_type.non_null?
          end
          if should_propagate_null
            propagate_nulls
          end
        end
        err
      end

      def propagate_nulls
        propagating_null = true
        highest_nulled_depth = path.size
        highest_list_depth = nil
        current_field_step = self
        while current_field_step
          return_type = current_field_step.field_definition.type
          if propagating_null && return_type.non_null?
            highest_nulled_depth = current_field_step.path.size
          else
            propagating_null = false
          end

          if return_type.list?
            highest_list_depth = current_field_step.path.size
          end

          current_field_step = current_field_step.selections_step.field_resolve_step
        end

        if highest_nulled_depth == 0
          # Actually everything should be killed here
          raise "TODO depth of zero"
        elsif highest_list_depth.nil? || highest_nulled_depth <= highest_list_depth
          kill_field_step = self
          while kill_field_step && highest_nulled_depth <= kill_field_step.path.size
            kill_field_step.selections_step.killed = true
            kill_field_step = kill_field_step.selections_step.field_resolve_step
          end
        end
      end

      def build_errors_result(errors, single_error)
        first_error = errors.nil? ? single_error : errors.pop
        @field_results = [first_error]
        @results = [@selections_step.results.first]
        if errors
          errors.each do |e|
            add_graphql_error(@results.first, key, e)
          end
        end
        build_results
      end

      def build_arguments
        query = @selections_step.query
        field_name = @ast_node.name
        @field_definition = query.types.field(@parent_type, field_name) || raise(GraphQL::Error, "No field definition found for #{@parent_type.to_type_signature}.#{ast_node.name} (at #{@ast_node.position})")
        set_current_field
        @arguments, errors = @runner.input_values[query].argument_values(@field_definition, @ast_node.arguments, self) # rubocop:disable Development/ContextIsPassedCop
        if errors
          build_errors_result(errors, nil)
          return
        end

        if (@pending_steps.nil? || @pending_steps.size == 0) &&
            @field_results.nil? # Make sure the arguments flow didn't already call through
          execute_field
        end
      ensure
        set_current_field(nil)
      end

      # Used for compatibility in Schema::Subscription
      def arguments_without_loads
        if @arguments_without_loads.nil?
          @arguments_without_loads, _errors = @runner.input_values[@selections_step.query].argument_values(@field_definition, ast_node.arguments, nil)
        end
        @arguments_without_loads
      end

      def execute_field
        objects = @selections_step.objects
        if @arguments.is_a?(GraphQL::RuntimeError)
          build_errors_result(nil, @arguments)
          return
        end

        @results = @selections_step.results
        query = @selections_step.query
        ctx = query.context
        if (v = @field_definition.validators).any?  # rubocop:disable Development/NoneWithoutBlockCop
          begin
            Schema::Validator.validate!(v, nil, ctx, @arguments)
          rescue GraphQL::RuntimeError => err
            build_errors_result(nil, err)
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
          objects = @selections_step.graphql_objects.map { |o| @field_definition.owner.wrap(o, ctx) }
        end

        if @runner.authorizes?(@field_definition, ctx)
          authorized_objects = []
          authorized_results = []
          l = objects.size
          i = 0
          while i < l
            o = objects[i]
            err = nil
            begin
              field_authed = @field_definition.authorized?(o, @arguments, ctx)
              if @runner.resolves_lazies && @runner.lazy?(field_authed)
                # TODO batch this properly...
                field_authed = sync(field_authed)
              end
            rescue GraphQL::UnauthorizedFieldError => field_auth_err
              err = field_auth_err
              err.field ||= @field_definition
              field_authed = false
            end

            if field_authed
              authorized_results << @results[i]
              authorized_objects << o
            else
              begin
                err ||= GraphQL::UnauthorizedFieldError.new(object: o, type: @parent_type, context: ctx, field: @field_definition)
                new_obj = query.schema.unauthorized_field(err)
                if !new_obj.nil?
                  authorized_objects << new_obj
                  authorized_results << @results[i]
                end
              rescue GraphQL::ExecutionError => exec_err
                add_graphql_error(@results[i], key, exec_err)
              end
            end
            i += 1
          end

          if authorized_objects.size == 0
            return
          end
          @results = authorized_results
        else
          authorized_objects = objects
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
                dir_args, errors = @runner.input_values[query].argument_values(dir_defn, dir_node.arguments, self)  # rubocop:disable Development/ContextIsPassedCop
                if errors
                  @results.each { |r| r.delete(@key) }
                  errors.each { |e| e.ast_node = dir_node }
                  build_errors_result(errors, nil)
                  return
                else
                  begin
                    dir_defn.validate!(dir_args, query.context)
                    if !(result = dir_defn.resolve_field(ast_nodes, @parent_type, field_definition, authorized_objects, dir_args, ctx)).nil?
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
                  rescue GraphQL::RuntimeError => err
                    err.ast_node = dir_node
                    raise
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
        elsif @pending_steps.nil? || @pending_steps.empty?
          if has_extensions
            finish_extensions
          else
            build_results
          end
        end
      rescue GraphQL::ExecutionError => err
        build_errors_result(nil, err)
      rescue StandardError => stderr
        begin
          @selections_step.query.handle_or_reraise(stderr, field: @field_definition, arguments: @arguments, object: nil)
        rescue GraphQL::ExecutionError => err
          add_graphql_error(@results[0], key, err)
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
            rescue GraphQL::RuntimeError => err
              err
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
          i = 0
          s = @results.size
          while i < s do
            result_h = @results[i]
            result = @field_results[i]
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
          i = 0
          s = @results.size
          while i < s do
            result_h = @results[i]
            field_result = @field_results[i]
            i += 1
            finish_leaf_result(result_h, @key, field_result, return_type, ctx)
          end
        end
      end

      def finish_leaf_result(result_h, key, field_result, return_type, ctx)
        final_field_result = build_leaf_result(result_h, key, field_result, return_type, ctx, false)

        @directive_finalizers&.each { |f| @runner.add_finalizer(ctx.query, result_h, key, f) }
        result_h[@key] = final_field_result
      end

      def build_leaf_result(result_h, result_key, field_result, return_type, ctx, is_from_array)
        if field_result.nil?
          if return_type.non_null?
            add_non_null_error(is_from_array)
          else
            nil
          end
        elsif field_result.is_a?(Finalizer)
          if field_result.is_a?(GraphQL::RuntimeError)
            add_graphql_error(result_h, result_key, field_result, return_type: return_type)
          else
            field_result.path = path
            @runner.add_finalizer(ctx.query, result_h, key, field_result)
          end
        elsif return_type.list?
          if return_type.non_null?
            return_type = return_type.of_type
          end

          inner_type = return_type.of_type
          result_a = Array.new(field_result.size)
          field_result.each_with_index do |item, idx|
            result_a[idx] = build_leaf_result(result_a, idx, item, inner_type, ctx, true)
          end
          result_a
        else
          return_type.coerce_result(field_result, ctx)
        end
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
                query.current_trace.begin_resolve_type(@static_type, next_object, query.context)
                object_type = ResolveTypeStep.resolve_type(@static_type, next_object, query)
                if object_type.is_a?(Array)
                  object_type, next_object = object_type
                end
                if @runner.resolves_lazies && @runner.lazy?(object_type)
                  # TODO batch this
                  object_type, next_object = sync(object_type)
                end
                ResolveTypeStep.assert_valid_resolved_type(@static_type, object_type, next_object, self)
                query.current_trace.end_resolve_type(@static_type, next_object, query.context, object_type)
                @runner.runtime_type_at[result] = object_type
              end
              next_objects_by_type[object_type] << next_object
              next_results_by_type[object_type] << result
            end

            next_objects_by_type.each do |obj_type, next_objects|
              query.current_trace.objects(obj_type, next_objects, ctx)
              @runner.add_step(SelectionsStep.new(
                path: path,
                field_resolve_step: self,
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
              field_resolve_step: self,
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
        err = @parent_type::InvalidNullError.new(@parent_type, @field_definition, ast_nodes, is_from_array: is_from_array, path: path)
        nn_result = @runner.schema.type_error(err, @selections_step.query.context)
        if nn_result.nil?
          propagate_nulls
        end
        nn_result
      end

      def set_current_field(new_value = @field_definition)
        Fiber[:__graphql_current_field] = new_value
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
            add_graphql_error(graphql_result, key, field_result)
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
        elsif @runner.resolves_lazies || (
                @static_type.kind.object? ?
                  @runner.authorizes?(@static_type, @selections_step.query.context) :
                  (
                    (runtime_type, _ignored_new_value = ResolveTypeStep.resolve_type(@static_type, field_result, @selections_step.query)) &&
                    (@runner.runtime_type_at[graphql_result] = runtime_type) &&
                    @runner.authorizes?(runtime_type, @selections_step.query.context)
                  ))
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
        dyn_ins = @field_definition.dynamic_introspection
        method_receiver = dyn_ins ? @field_definition.owner : @parent_type
        case @field_definition.execution_mode
        when :resolve_batch
          begin
            method_receiver.public_send(@field_definition.execution_mode_key, objects, context, **args_hash)
          rescue GraphQL::ExecutionError => exec_err
            error_instance_array(objects.size, exec_err)
          rescue StandardError => stderr
            begin
              context.query.handle_or_reraise(stderr, field: @field_definition, arguments: @arguments, object: nil)
            rescue GraphQL::ExecutionError => exec_err
              error_instance_array(objects.size, exec_err)
            end
          end
        when :resolve_static
          result = begin
            method_receiver.public_send(@field_definition.execution_mode_key, context, **args_hash)
          rescue GraphQL::ExecutionError => err
            err
          rescue StandardError => stderr
            begin
              context.query.handle_or_reraise(stderr, field: @field_definition, arguments: @arguments, object: nil)
            rescue GraphQL::ExecutionError => err
              err
            end
          end
          Array.new(objects.size, result)
        when :resolve_each
          objects.map do |o|
            passed_in_obj = dyn_ins ? o.object : o
            method_receiver.public_send(@field_definition.execution_mode_key, passed_in_obj, context, **args_hash)
          rescue GraphQL::ExecutionError => err
            err
          rescue StandardError => stderr
            begin
              context.query.handle_or_reraise(stderr, field: @field_definition, arguments: @arguments, object: o)
            rescue GraphQL::ExecutionError => err
              err
            end
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
              @selections_step.query.handle_or_reraise(stderr, object: o, field: @field_definition, arguments: args_hash)
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
            obj_inst.public_send(@field_definition.execution_mode_key, **args_hash)
          rescue GraphQL::ExecutionError => exec_err
            exec_err
          end
        else
          raise "Batching execution for #{path} not implemented (execution_mode: #{@execution_mode.inspect}); provide `resolve_static:`, `resolve_batch:`, `hash_key:`, `method:`, or use a compatibility plug-in"
        end
      end

      def error_instance_array(size, err_prototype)
        Array.new(size) { err_prototype.dup }
      end
    end
  end
end
