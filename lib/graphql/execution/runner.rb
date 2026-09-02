# frozen_string_literal: true
module GraphQL
  module Execution
    class Runner
      def initialize(multiplex)
        @multiplex = multiplex
        @schema = multiplex.schema
        @runtime_type_at = {}.compare_by_identity
        @static_type_at = {}.compare_by_identity
        @finalizers = nil
        @selected_operation = nil
        # Groups of steps to be run: everything in a group is run together,
        # and each group is finished before the next one begins.
        @isolated_steps = [[]]
        @dataloader = multiplex.context[:dataloader] ||= @schema.dataloader_class.new
        @resolves_lazies = @schema.resolves_lazies?
        @input_values = Hash.new do |h, query|
          h[query] = InputValues.new(query, self)
        end.compare_by_identity

        @runtime_directives = nil
        @schema.directives.each do |name, dir_class|
          if dir_class.runtime? && name != "include" && name != "skip"
            @runtime_directives ||= {}
            @runtime_directives[dir_class.graphql_name] = dir_class
          end
        end

        if @runtime_directives.nil?
          @uses_runtime_directives = false
          @runtime_directives = EmptyObjects::EMPTY_HASH
        else
          @uses_runtime_directives = true
        end

        @lazy_cache = resolves_lazies ? {}.compare_by_identity : nil
        @authorizes_cache = Hash.new do |h, query_context|
          h[query_context] = {}.compare_by_identity
        end.compare_by_identity
      end

      attr_reader :runtime_directives, :uses_runtime_directives, :finalizer_keys

      def authorizes?(graphql_definition, query_context)
        auth_cache = @authorizes_cache[query_context]
        case (auth_res = auth_cache[graphql_definition])
        when nil
          auth_cache[graphql_definition] = graphql_definition.authorizes?(query_context)
        else
          auth_res
        end
      end

      def add_step(step)
        @dataloader.append_job(step)
      end

      attr_reader :schema, :variables, :dataloader, :resolves_lazies, :authorizes, :static_type_at, :runtime_type_at, :finalizers, :input_values

      # @return [void]
      def add_finalizer(query, result_value, key, finalizer)
        @finalizers ||= {}.compare_by_identity
        f_for_query = @finalizers[query] ||= {}.compare_by_identity
        f_for_result = f_for_query[result_value] ||= {}.compare_by_identity
        if (f = f_for_result[key])
          if f.is_a?(Array)
            f << finalizer
          else
            f_for_result[key] = [f, finalizer]
          end
        else
          f_for_result[key] = finalizer
        end
        nil
      end

      def execute
        with_current_multiplex do
          trace = @multiplex.current_trace
          trace.execute_multiplex(multiplex: @multiplex) do
            analyze_multiplex(trace)
            results = begin_queries(trace)
            run_steps(trace)
            @multiplex.queries.each_with_index.map { |query, idx| finish_query(query, results[idx]) }
          end
        rescue SystemStackError => err
          handle_stack_error(err)
        end
      end

      def gather_selections(type_defn, ast_selections, selections_step, query, all_selections, prototype_result, into:)
        ast_selections.each do |ast_selection|
          next if !directives_include?(query, ast_selection)

          case ast_selection
          when GraphQL::Language::Nodes::Field
            key = ast_selection.alias || ast_selection.name
            step = into[key] ||= begin
              prototype_result[key] = nil

              FieldResolveStep.new(
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
              if uses_runtime_directives && !ast_selection.directives.empty?
                all_selections << (into = { __node: ast_selection })
                all_selections << (prototype_result = {})
              end
              gather_selections(type_defn, ast_selection.selections, selections_step, query, all_selections, prototype_result, into: into)
            end
          when GraphQL::Language::Nodes::FragmentSpread
            fragment_definition = query.fragments[ast_selection.name]
            type_condition = fragment_definition.type.name
            if type_condition_applies?(query.context, type_defn, type_condition)
              if uses_runtime_directives && !ast_selection.directives.empty?
                all_selections << (into = { __node: ast_selection })
                all_selections << (prototype_result = {})
              end
              gather_selections(type_defn, fragment_definition.selections, selections_step, query, all_selections, prototype_result, into: into)
            end
          else
            raise ArgumentError, "Unsupported graphql selection node: #{ast_selection.class} (#{ast_selection.inspect})"
          end
        end
      end

      def lazy?(object)
        obj_class = object.class
        is_lazy = @lazy_cache[obj_class]
        if is_lazy.nil?
          is_lazy = @lazy_cache[obj_class] = @schema.lazy?(object)
        end
        is_lazy
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

      private

      # Make this multiplex the current one for the duration of the block,
      # then put back whatever was there before.
      def with_current_multiplex
        previous_multiplex = Fiber[:__graphql_current_multiplex]
        Fiber[:__graphql_current_multiplex] = @multiplex
        yield
      ensure
        Fiber[:__graphql_current_multiplex] = previous_multiplex
      end

      def analyze_multiplex(trace)
        multiplex_analyzers = @schema.multiplex_analyzers
        if @multiplex.max_complexity
          multiplex_analyzers += [GraphQL::Analysis::MaxQueryComplexity]
        end
        trace.begin_analyze_multiplex(@multiplex, multiplex_analyzers)
        @schema.analysis_engine.analyze_multiplex(@multiplex, multiplex_analyzers)
        trace.end_analyze_multiplex(@multiplex, multiplex_analyzers)
      end

      # Validate each query and enqueue the steps it starts with.
      # @return [Array<Hash>] Partial results, in query order
      def begin_queries(trace)
        results = []
        @multiplex.queries.each do |query|
          begin_query(trace, query, results)
        end
        results
      end

      def begin_query(trace, query, results)
        if query.validate && !query.valid?
          results << { "errors" => query.static_errors.map(&:to_h) }
          return
        end

        root_type = query.root_type
        if root_type.non_null?
          root_type = root_type.of_type
        end

        root_value = query.root_value
        if resolves_lazies
          root_value = schema.sync_lazy(root_value)
        end

        trace.execute_query(query: query) do
          begin_execute(results, query, root_type, root_value)
        end
      rescue GraphQL::RuntimeError => err
        err.ast_node = query.selected_operation
        err.path = query.path
        query.context.add_error(err)
      end

      # Run enqueued steps until there aren't any left. Steps in the same group are
      # run together; each following group begins after the previous one is finished.
      def run_steps(trace)
        traced_query = @multiplex.queries.size == 1 ? @multiplex.queries.first : nil
        trace.execute_query_lazy(query: traced_query, multiplex: @multiplex) do
          while (next_isolated_steps = @isolated_steps.shift)
            next_isolated_steps.each do |step|
              add_step(step)
            end
            @dataloader.run
          end
        end
      end

      def finish_query(query, result)
        query.result_values = result_values_for(query, result)
        if query.context.namespace?(:__query_result_extensions__)
          query.result_values["extensions"] = query.context.namespace(:__query_result_extensions__)
        end
        query.result
      end

      def result_values_for(query, result)
        if (!@finalizers&.key?(query) && query.context.errors.empty?) || !query.valid?
          return result
        end

        data = if result
          Finalize.new(query, result["data"], self).run
        end

        errors = query.context.errors.filter_map { |err| err.to_h if err.respond_to?(:to_h) }

        res_h = {}
        if !errors.empty?
          res_h["errors"] = errors
        end
        res_h["data"] = data
        res_h
      end

      def handle_stack_error(err)
        @multiplex.queries.map do |query|
          @schema.query_stack_error(query, err)
          query.result_values ||= { "errors" => query.context.errors.map(&:to_h) }
          query.result
        end
      end

      # Set up the first steps for this query, based on the kind of its root type.
      def begin_execute(results, query, root_type, root_value)
        data = {}
        @static_type_at[data] = root_type
        path = query.path

        case root_type.kind.name
        when "OBJECT"
          begin_object_root(results, query, root_type, root_value, data, path)
        when "UNION", "INTERFACE"
          begin_abstract_root(results, query, root_type, root_value, data, path)
        when "LIST"
          begin_list_root(results, query, root_type, root_value, path)
        when "SCALAR", "ENUM"
          results << run_isolated_scalar(root_type, query)
        else
          raise "Unhandled root type kind: #{root_type.kind.name.inspect}"
        end
      end

      def begin_object_root(results, query, root_type, root_value, data, path)
        objects = [root_value]
        if !authorize_root_object(query, root_type, objects, path)
          results << {}
          return
        end

        results << { "data" => data }
        query.current_trace.objects(root_type, objects, query.context)

        if !run_operation_directives(query, objects, data, path)
          return
        end

        enqueue_operation_steps(query, root_type, objects, data, path)
      end

      def authorize_root_object(query, root_type, objects, path)
        if !authorizes?(root_type, query.context)
          return true
        end

        root_value = objects[0]
        query.current_trace.begin_authorized(root_type, root_value, query.context)
        auth_check = schema.sync_lazy(root_type.authorized?(root_value, query.context))
        query.current_trace.end_authorized(root_type, root_value, query.context, auth_check)
        if auth_check
          return true
        end

        begin
          auth_err = GraphQL::UnauthorizedError.new(object: root_value, type: root_type, context: query.context)
          new_val = schema.unauthorized_object(auth_err)
          if new_val
            objects[0] = new_val
            true
          else
            false
          end
        rescue GraphQL::ExecutionError => ex_err
          # The old runtime didn't add path and ast_nodes to this
          ex_err.path = path
          query.context.add_error(ex_err)
          false
        end
      end

      # @return [Boolean] `false` if one of the directives halted this operation
      def run_operation_directives(query, objects, data, path)
        if !query.is_a?(GraphQL::Query) || !uses_runtime_directives
          return true
        end

        selected_operation = query.selected_operation
        query_dirs = selected_operation.directives
        if query_dirs.empty?
          return true
        end

        query_dirs.each do |dir_node|
          dir_defn = runtime_directives[dir_node.name] || raise(GraphQL::Error, "No directive definition found for: #{dir_node.name.inspect}")
          dir_args, errors = input_values[query].argument_values(dir_defn, dir_node.arguments, nil) # rubocop:disable Development/ContextIsPassedCop
          if errors
            errors.each { |e|
              e.ast_node = dir_node
              e.path = path
              query.context.add_error(e)
            }
            return false
          end

          result = dir_defn.resolve_operation(selected_operation, query, objects, dir_args, query.context)
          if result.is_a?(Finalizer)
            result.path = path
            add_finalizer(query, data, nil, result)
            if result.is_a?(HaltExecution)
              return false
            end
          end
        end

        true
      end

      def enqueue_operation_steps(query, root_type, objects, data, path)
        if query.query?
          enqueue_step(root_selections_step(query, root_type, objects, [data], path))
        elsif query.mutation?
          enqueue_mutation_steps(query, root_type, objects, data, path)
        elsif query.subscription?
          if !query.subscription_update?
            schema.subscriptions.initialize_subscriptions(query)
            add_finalizer(query, data, nil, schema.subscriptions.finalizer)
          end
          enqueue_step(root_selections_step(query, root_type, objects, [data], path))
        else
          raise ArgumentError, "Unknown operation type (not query, mutation or subscription): #{query.query_string}"
        end
      end

      # Each root mutation field gets a group of its own, so that they're resolved one-at-a-time, in order.
      def enqueue_mutation_steps(query, root_type, objects, data, path)
        fields = {}
        all_selections = [fields, (prototype_result = {})]
        gather_selections(root_type, query.selected_operation.selections, nil, query, all_selections, prototype_result, into: fields)
        if all_selections.length > 2
          # TODO DRY with SelectionsStep with directive handling
          raise "Directives on root mutation type not implemented yet"
        end

        fields.each_value do |field_resolve_step|
          enqueue_isolated_step(SelectionsStep.new(
            clobber: false, # `data` is being shared among several selections steps
            parent_type: root_type,
            field_resolve_step: field_resolve_step,
            selections: field_resolve_step.ast_nodes || Array(field_resolve_step.ast_node),
            objects: objects,
            results: [data],
            path: path,
            runner: self,
            query: query,
          ))
        end
      end

      def begin_abstract_root(results, query, root_type, root_value, data, path)
        resolved_type = ResolveTypeStep.resolve_type(root_type, root_value, query)
        if resolves_lazies && lazy?(resolved_type)
          resolved_type = schema.sync_lazy(resolved_type)
        end
        resolved_type, root_value = resolved_type
        ResolveTypeStep.assert_valid_resolved_type(root_type, resolved_type, root_value, nil, query: query)
        objects = [root_value]
        query.current_trace.objects(resolved_type, objects, query.context)
        runtime_type_at[data] = resolved_type
        results << { "data" => data }
        enqueue_step(root_selections_step(query, resolved_type, objects, [data], path))
      end

      def begin_list_root(results, query, root_type, root_value, path)
        inner_type = root_type.unwrap
        case inner_type.kind.name
        when "SCALAR", "ENUM"
          results << run_isolated_scalar(root_type, query)
        else
          list_result = Array.new(root_value.size) { Hash.new.compare_by_identity }
          results << { "data" => list_result }
          enqueue_step(root_selections_step(query, inner_type, root_value, list_result, path))
        end
      end

      def root_selections_step(query, parent_type, objects, results, path)
        SelectionsStep.new(
          parent_type: parent_type,
          field_resolve_step: nil,
          selections: query.selected_operation.selections,
          objects: objects,
          results: results,
          path: path,
          runner: self,
          query: query,
        )
      end

      # Add a step to the current group, to be run along with the other steps in it.
      def enqueue_step(step)
        @isolated_steps[0] << step
        nil
      end

      # Add a step in a group of its own, to be run after all previously-added groups.
      def enqueue_isolated_step(step)
        @isolated_steps << [step]
        nil
      end

      def directives_include?(query, ast_selection)
        if ast_selection.directives.any? { |dir_node|
              case dir_node.name
              when "skip"
                skip_args, _errors = @input_values[query].argument_values(GraphQL::Schema::Directive::Skip, dir_node.arguments, nil) # rubocop:disable Development/ContextIsPassedCop
                skip_args[:if] == true
              when "include"
                include_args, _errors = @input_values[query].argument_values(GraphQL::Schema::Directive::Include, dir_node.arguments, nil) # rubocop:disable Development/ContextIsPassedCop
                include_args[:if] == false
              else
                dir_defn = runtime_directives[dir_node.name]
                dir_args, _errors = @input_values[query].argument_values(dir_defn, dir_node.arguments, nil) # rubocop:disable Development/ContextIsPassedCop
                !dir_defn.include?(nil, dir_args, query.context)
              end
            }
          false
        else
          true
        end
      end

      def run_isolated_scalar(type, partial)
        value = partial.root_value
        dummy_path = partial.path.dup
        key = dummy_path.pop
        is_from_array = key.is_a?(Integer)

        if lazy?(value)
          value = @schema.sync_lazy(value)
        end
        selections = partial.ast_nodes
        dummy_ss = SelectionsStep.new(
          parent_type: nil,
          field_resolve_step: nil,
          selections: selections,
          objects: nil,
          results: nil,
          path: dummy_path,
          runner: self,
          query: partial,
        )
        dummy_frs = FieldResolveStep.new(
          selections_step: dummy_ss,
          key: key,
          parent_type: nil,
          runner: self,
        )
        dummy_frs.static_type = type
        selections.each { |s| dummy_frs.append_selection(s) }

        result = is_from_array ? [] : {}
        dummy_frs.finish_leaf_result(result, key, value, type, partial.context)
        { "data" => result[key] }
      end
    end
  end
end
