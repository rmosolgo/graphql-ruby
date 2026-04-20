# frozen_string_literal: true
module GraphQL
  module Execution
    class Runner
      def initialize(multiplex, authorization:)
        @multiplex = multiplex
        @schema = multiplex.schema
        @steps_queue = []
        @runtime_type_at = {}.compare_by_identity
        @static_type_at = {}.compare_by_identity
        @finalizers = nil
        @selected_operation = nil
        @dataloader = multiplex.context[:dataloader] ||= @schema.dataloader_class.new
        @resolves_lazies = @schema.resolves_lazies?

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
        @authorization = authorization
        if @authorization
          @authorizes_cache = Hash.new do |h, query_context|
            h[query_context] = {}.compare_by_identity
          end.compare_by_identity
        end
      end

      attr_reader :runtime_directives, :uses_runtime_directives, :finalizer_keys

      def resolve_type(type, object, query)
        query.current_trace.begin_resolve_type(type, object, query.context)
        resolved_type, _ignored_new_value = query.resolve_type(type, object)
        query.current_trace.end_resolve_type(type, object, query.context, resolved_type)
        resolved_type
      end

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

      attr_reader :authorization, :steps_queue, :schema, :variables, :dataloader, :resolves_lazies, :authorizes, :static_type_at, :runtime_type_at, :finalizers

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

            root_type = query.root_type

            if root_type.non_null?
              root_type = root_type.of_type
            end

            root_value = query.root_value
            if resolves_lazies
              root_value = schema.sync_lazy(root_value)
            end

            trace.execute_query(query: query) do
              begin_execute(isolated_steps, results, query, root_type, root_value)
            end
          end

          trace.execute_query_lazy(query: nil, multiplex: @multiplex) do
            while (next_isolated_steps = isolated_steps.shift)
              next_isolated_steps.each do |step|
                add_step(step)
              end
              @dataloader.run
            end
          end

          queries.each_with_index.map do |query, idx|
            result = results[idx]

            fin_result = if (!@finalizers&.key?(query) && query.context.errors.empty?) || !query.valid?
              result
            else
              data = result["data"]
              data = Finalize.new(query, data, self).run
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

            query.result_values = fin_result
            query.result
          end
        end
      ensure
        Fiber[:__graphql_current_multiplex] = nil
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

      def begin_execute(isolated_steps, results, query, root_type, root_value)
        data = {}
        selected_operation = query.selected_operation
        beginning_path = query.path

        case root_type.kind.name
        when "OBJECT"
          if self.authorization && authorizes?(root_type, query.context)
            query.current_trace.begin_authorized(root_type, root_value, query.context)
            auth_check = schema.sync_lazy(root_type.authorized?(root_value, query.context))
            query.current_trace.end_authorized(root_type, root_value, query.context, auth_check)
            root_value = if auth_check
              root_value
            else
              begin
                auth_err = GraphQL::UnauthorizedError.new(object: root_value, type: root_type, context: query.context)
                new_val = schema.unauthorized_object(auth_err)
                if new_val
                  auth_check = true
                end
                new_val
              rescue GraphQL::ExecutionError => ex_err
                # The old runtime didn't add path and ast_nodes to this
                ex_err.path = beginning_path
                query.context.add_error(ex_err)
                nil
              end
            end

            if !auth_check
              results << {}
              return
            end
          end

          results << { "data" => data }
          objects = [root_value]
          query.current_trace.objects(root_type, objects, query.context)

          if query.query?
            isolated_steps[0] << SelectionsStep.new(
              parent_type: root_type,
              selections: query.selected_operation.selections,
              objects: objects,
              results: [data],
              path: beginning_path,
              runner: self,
              query: query,
            )
          elsif query.mutation?
            fields = {}
            all_selections = [fields, (prototype_result = {})]
            gather_selections(root_type, selected_operation.selections, nil, query, all_selections, prototype_result, into: fields)
            if all_selections.length > 2
              # TODO DRY with SelectionsStep with directive handling
              raise "Directives on root mutation type not implemented yet"
            end
            fields.each_value do |field_resolve_step|
              isolated_steps << [SelectionsStep.new(
                clobber: false, # `data` is being shared among several selections steps
                parent_type: root_type,
                selections: field_resolve_step.ast_nodes || Array(field_resolve_step.ast_node),
                objects: objects,
                results: [data],
                path: beginning_path,
                runner: self,
                query: query,
              )]
            end
          elsif query.subscription?
            if !query.subscription_update?
              schema.subscriptions.initialize_subscriptions(query)
              add_finalizer(query, data, nil, schema.subscriptions.finalizer)
            end
            isolated_steps[0] << SelectionsStep.new(
              parent_type: root_type,
              selections: selected_operation.selections,
              objects: objects,
              results: [data],
              path: beginning_path,
              runner: self,
              query: query,
            )
          else
            raise ArgumentError, "Unknown operation type (not query, mutation or subscription): #{query.query_string}"
          end
        when "UNION", "INTERFACE"
          resolved_type = resolve_type(root_type, root_value, query)
          if resolves_lazies
            resolved_type = schema.sync_lazy(resolved_type)
          end
          objects = [root_value]
          query.current_trace.objects(resolved_type, objects, query.context)
          runtime_type_at[data] = resolved_type
          results << { "data" => data }
          isolated_steps[0] << SelectionsStep.new(
            parent_type: resolved_type,
            selections: query.selected_operation.selections,
            objects: objects,
            results: [data],
            path: beginning_path,
            runner: self,
            query: query,
          )
        when "LIST"
          inner_type = root_type.unwrap
          case inner_type.kind.name
          when "SCALAR", "ENUM"
            results << run_isolated_scalar(root_type, query)
          else
            list_result = Array.new(root_value.size) { Hash.new.compare_by_identity }
            results << { "data" => list_result }
            isolated_steps[0] << SelectionsStep.new(
              parent_type: inner_type,
              selections: query.selected_operation.selections,
              objects: root_value,
              results: list_result,
              path: beginning_path,
              runner: self,
              query: query,
            )
          end
        when "SCALAR", "ENUM"
          results << run_isolated_scalar(root_type, query)
        else
          raise "Unhandled root type kind: #{root_type.kind.name.inspect}"
        end

        @static_type_at[data] = root_type
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
