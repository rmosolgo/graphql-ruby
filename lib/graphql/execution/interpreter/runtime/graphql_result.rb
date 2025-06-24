# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class Runtime
        module GraphQLResult
          def initialize(runtime_instance, result_name, result_type, application_value, parent_result, is_non_null_in_parent, selections, is_eager, ast_node, graphql_arguments, graphql_field) # rubocop:disable Metrics/ParameterLists
            @runtime = runtime_instance
            @ast_node = ast_node
            @graphql_arguments = graphql_arguments
            @graphql_field = graphql_field
            @graphql_parent = parent_result
            @graphql_application_value = application_value
            @graphql_result_type = result_type
            if parent_result && parent_result.graphql_dead
              @graphql_dead = true
            end
            @graphql_result_name = result_name
            @graphql_is_non_null_in_parent = is_non_null_in_parent
            # Jump through some hoops to avoid creating this duplicate storage if at all possible.
            @graphql_metadata = nil
            @graphql_selections = selections
            @graphql_is_eager = is_eager
            @base_path = nil
            @graphql_depth = nil
          end

          # TODO test full path in Partial
          attr_writer :base_path

          def path
            @path ||= build_path([])
          end

          def build_path(path_array)
            graphql_result_name && path_array.unshift(graphql_result_name)
            if @graphql_parent
              @graphql_parent.build_path(path_array)
            elsif @base_path
              @base_path + path_array
            else
              path_array
            end
          end

          attr_accessor :graphql_dead
          attr_reader :graphql_parent, :graphql_result_name, :graphql_is_non_null_in_parent,
            :graphql_application_value, :graphql_result_type, :graphql_selections, :graphql_is_eager, :ast_node, :graphql_arguments, :graphql_field

          # @return [Hash] Plain-Ruby result data (`@graphql_metadata` contains Result wrapper objects)
          attr_accessor :graphql_result_data
        end

        class GraphQLResultHash

          def initialize(_runtime_inst, _result_name, _result_type, _application_value, _parent_result, _is_non_null_in_parent, _selections, _is_eager, _ast_node, _graphql_arguments, graphql_field) # rubocop:disable Metrics/ParameterLists
            super
            @graphql_result_data = {}
            @ordered_result_keys = nil
            @target_result = nil
            @was_scoped = nil
            @step = 0
          end

          def depth
            @graphql_depth ||= begin
              parent_depth = @graphql_parent ? @graphql_parent.depth : 0
              parent_depth + 1
            end
          end

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}(#{@graphql_result_type.to_type_signature} @ #{path.join(".")}})"
          end

          def step_finished?
            @step == 4
          end

          def value
            @graphql_application_value = @runtime.schema.sync_lazy(@graphql_application_value)
          end

          def run_step
            @step += 1
            case @step
            when 1
              @graphql_application_value = begin
                value = @graphql_application_value
                context = @runtime.context
                @was_scoped ? @graphql_result_type.wrap_scoped(value, context) : @graphql_result_type.wrap(value, context)
              rescue GraphQL::ExecutionError => err
                err
              end
            when 2
              @graphql_application_value = @runtime.continue_value(@graphql_application_value, @graphql_field, @graphql_is_non_null_in_parent, @ast_node, @graphql_result_name, @graphql_parent)
              if HALT.equal?(@graphql_application_value)
                @step = 4
              elsif @graphql_parent
                @runtime.set_result(@graphql_parent, @graphql_result_name, self, true, @graphql_is_non_null_in_parent)
              end
              nil
            when 3
              @runtime.each_gathered_selections(self) do |gathered_selections, is_selection_array, ordered_result_keys|
                @ordered_result_keys ||= ordered_result_keys
                if is_selection_array
                  selections_result = GraphQLResultHash.new(
                    @runtime,
                    @graphql_result_name,
                    @graphql_result_type,
                    @graphql_application_value,
                    @graphql_parent,
                    @graphql_is_non_null_in_parent,
                    gathered_selections,
                    @graphql_is_eager,
                    @ast_node,
                    @graphql_arguments,
                    @graphql_field)
                  selections_result.target_result = self
                  selections_result.ordered_result_keys = ordered_result_keys
                else
                  selections_result = self
                  @target_result = nil
                  @graphql_selections = gathered_selections
                end
                runtime_state = @runtime.get_current_runtime_state
                runtime_state.current_result_name = nil
                runtime_state.current_result = selections_result
                # This is a less-frequent case; use a fast check since it's often not there.
                if (directives = gathered_selections[:graphql_directives])
                  gathered_selections.delete(:graphql_directives)
                  dir_step = DirectivesStep.new(@runtime, selections_result.graphql_application_value, :resolve, directives, selections_result)
                  @runtime.run_queue.append_step(dir_step)
                elsif @target_result.nil?
                  run_step # Run itself again
                else
                  @runtime.run_queue.append_step(selections_result)
                end
              end
            when 4
              @graphql_selections.each do |result_name, field_ast_nodes_or_ast_node|
                # Field resolution may pause the fiber,
                # so it wouldn't get to the `Resolve` call that happens below.
                # So instead trigger a run from this outer context.
                if @graphql_is_eager
                  prev_queue = @runtime.run_queue
                  @runtime.run_queue = RunQueue.new(runtime: @runtime)
                  @runtime.dataloader.clear_cache
                  @runtime.dataloader.run_isolated {
                    evaluate_selection(
                      result_name, field_ast_nodes_or_ast_node
                    )
                    @runtime.dataloader.clear_cache
                  }
                  @runtime.run_queue.complete(eager: true)
                  @runtime.run_queue = prev_queue
                else
                  @runtime.dataloader.append_job {
                    evaluate_selection(
                      result_name, field_ast_nodes_or_ast_node
                    )
                  }
                end
              end
              # TODO I'm pretty sure finished_jobs/enqueued_jobs actually did nothing
              if @target_result
                self.merge_into(@target_result)
              end
            end
          end

          def evaluate_selection(result_name, field_ast_nodes_or_ast_node) # rubocop:disable Metrics/ParameterLists
            return if @graphql_dead
            # As a performance optimization, the hash key will be a `Node` if
            # there's only one selection of the field. But if there are multiple
            # selections of the field, it will be an Array of nodes
            if field_ast_nodes_or_ast_node.is_a?(Array)
              field_ast_nodes = field_ast_nodes_or_ast_node
              ast_node = field_ast_nodes.first
            else
              field_ast_nodes = nil
              ast_node = field_ast_nodes_or_ast_node
            end
            field_name = ast_node.name
            owner_type = @graphql_result_type
            field_defn = @runtime.query.types.field(owner_type, field_name)

            # Set this before calling `run_with_directives`, so that the directive can have the latest path
            runtime_state = @runtime.get_current_runtime_state
            runtime_state.current_field = field_defn
            runtime_state.current_result = self
            runtime_state.current_result_name = result_name

            owner_object = @graphql_application_value
            if field_defn.dynamic_introspection
              owner_object = field_defn.owner.wrap(owner_object, @runtime.context)
            end

            if !field_defn.any_arguments?
              resolved_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
              if field_defn.extras.size == 0
                evaluate_selection_with_resolved_keyword_args(
                  EmptyObjects::EMPTY_HASH, resolved_arguments, field_defn, ast_node, field_ast_nodes, owner_object, result_name, runtime_state
                )
              else
                evaluate_selection_with_args(resolved_arguments, field_defn, ast_node, field_ast_nodes, owner_object, result_name, runtime_state)
              end
            else
              @runtime.query.arguments_cache.dataload_for(ast_node, field_defn, owner_object) do |resolved_arguments|
                runtime_state = @runtime.get_current_runtime_state # This might be in a different fiber
                evaluate_selection_with_args(resolved_arguments, field_defn, ast_node, field_ast_nodes, owner_object, result_name, runtime_state)
              end
            end
          end

          def evaluate_selection_with_args(arguments, field_defn, ast_node, field_ast_nodes, object, result_name, runtime_state)  # rubocop:disable Metrics/ParameterLists
            # TODO make this a step
            @runtime.after_lazy(arguments, field: field_defn, ast_node: ast_node, owner_object: object, arguments: arguments, result_name: result_name, result: self, runtime_state: runtime_state) do |resolved_arguments, runtime_state|
              if resolved_arguments.is_a?(GraphQL::ExecutionError) || resolved_arguments.is_a?(GraphQL::UnauthorizedError)
                return_type_non_null = field_defn.type.non_null?
                continue_value(resolved_arguments, field_defn, return_type_non_null, ast_node, result_name, self)
                next
              end

              kwarg_arguments = if field_defn.extras.empty?
                if resolved_arguments.empty?
                  # We can avoid allocating the `{ Symbol => Object }` hash in this case
                  EmptyObjects::EMPTY_HASH
                else
                  resolved_arguments.keyword_arguments
                end
              else
                # Bundle up the extras, then make a new arguments instance
                # that includes the extras, too.
                extra_args = {}
                field_defn.extras.each do |extra|
                  case extra
                  when :ast_node
                    extra_args[:ast_node] = ast_node
                  when :execution_errors
                    extra_args[:execution_errors] = ExecutionErrors.new(@runtime.context, ast_node, @runtime.current_path)
                  when :path
                    extra_args[:path] = @runtime.current_path
                  when :lookahead
                    if !field_ast_nodes
                      field_ast_nodes = [ast_node]
                    end

                    extra_args[:lookahead] = Execution::Lookahead.new(
                      query: @runtime.query,
                      ast_nodes: field_ast_nodes,
                      field: field_defn,
                    )
                  when :argument_details
                    # Use this flag to tell Interpreter::Arguments to add itself
                    # to the keyword args hash _before_ freezing everything.
                    extra_args[:argument_details] = :__arguments_add_self
                  when :parent
                    parent_result = @graphql_parent
                    if parent_result.is_a?(GraphQL::Execution::Interpreter::Runtime::GraphQLResultArray)
                      parent_result = parent_result.graphql_parent
                    end
                    parent_value = parent_result&.graphql_application_value&.object
                    extra_args[:parent] = parent_value
                  else
                    extra_args[extra] = field_defn.fetch_extra(extra, @runtime.context)
                  end
                end
                if !extra_args.empty?
                  resolved_arguments = resolved_arguments.merge_extras(extra_args)
                end
                resolved_arguments.keyword_arguments
              end

              evaluate_selection_with_resolved_keyword_args(kwarg_arguments, resolved_arguments, field_defn, ast_node, field_ast_nodes, object, result_name, runtime_state)
            end
          end

          def evaluate_selection_with_resolved_keyword_args(kwarg_arguments, resolved_arguments, field_defn, ast_node, field_ast_nodes, object, result_name, runtime_state)  # rubocop:disable Metrics/ParameterLists
            # Optimize for the case that field is selected only once
            if field_ast_nodes.nil? || field_ast_nodes.size == 1
              next_selections = ast_node.selections
              directives = ast_node.directives
            else
              next_selections = []
              directives = []
              field_ast_nodes.each { |f|
                next_selections.concat(f.selections)
                directives.concat(f.directives)
              }
            end

            resolve_field_step = FieldResolveStep.new(@runtime, field_defn, object, ast_node, kwarg_arguments, resolved_arguments, result_name, self, next_selections)
            @runtime.run_queue.append_step(if !directives.empty?
              # TODO this will get clobbered by other steps in the queue
              runtime_state.current_field = field_defn
              runtime_state.current_arguments = resolved_arguments
              runtime_state.current_result_name = result_name
              runtime_state.current_result = self
              DirectivesStep.new(@runtime, object, :resolve, directives, resolve_field_step)
            else
              resolve_field_step
            end)
          end

          attr_accessor :ordered_result_keys, :target_result, :was_scoped

          include GraphQLResult

          attr_accessor :graphql_merged_into

          def set_leaf(key, value)
            # This is a hack.
            # Basically, this object is merged into the root-level result at some point.
            # But the problem is, some lazies are created whose closures retain reference to _this_
            # object. When those lazies are resolved, they cause an update to this object.
            #
            # In order to return a proper top-level result, we have to update that top-level result object.
            # In order to return a proper partial result (eg, for a directive), we have to update this object, too.
            # Yowza.
            if (t = @graphql_merged_into)
              t.set_leaf(key, value)
            end

            before_size = @graphql_result_data.size
            @graphql_result_data[key] = value
            after_size = @graphql_result_data.size
            if after_size > before_size && @ordered_result_keys[before_size] != key
              fix_result_order
            end

            # keep this up-to-date if it's been initialized
            @graphql_metadata && @graphql_metadata[key] = value

            value
          end

          def set_child_result(key, value)
            if (t = @graphql_merged_into)
              t.set_child_result(key, value)
            end
            before_size = @graphql_result_data.size
            @graphql_result_data[key] = value.graphql_result_data
            after_size = @graphql_result_data.size
            if after_size > before_size && @ordered_result_keys[before_size] != key
              fix_result_order
            end

            # If we encounter some part of this response that requires metadata tracking,
            # then create the metadata hash if necessary. It will be kept up-to-date after this.
            (@graphql_metadata ||= @graphql_result_data.dup)[key] = value
            value
          end

          def delete(key)
            @graphql_metadata && @graphql_metadata.delete(key)
            @graphql_result_data.delete(key)
          end

          def each
            (@graphql_metadata || @graphql_result_data).each { |k, v| yield(k, v) }
          end

          def values
            (@graphql_metadata || @graphql_result_data).values
          end

          def key?(k)
            @graphql_result_data.key?(k)
          end

          def [](k)
            (@graphql_metadata || @graphql_result_data)[k]
          end

          def merge_into(into_result)
            self.each do |key, value|
              case value
              when GraphQLResultHash
                next_into = into_result[key]
                if next_into
                  value.merge_into(next_into)
                else
                  into_result.set_child_result(key, value)
                end
              when GraphQLResultArray
                # There's no special handling of arrays because currently, there's no way to split the execution
                # of a list over several concurrent flows.
                into_result.set_child_result(key, value)
              else
                # We have to assume that, since this passed the `fields_will_merge` selection,
                # that the old and new values are the same.
                into_result.set_leaf(key, value)
              end
            end
            @graphql_merged_into = into_result
          end

          def fix_result_order
            @ordered_result_keys.each do |k|
              if @graphql_result_data.key?(k)
                @graphql_result_data[k] = @graphql_result_data.delete(k)
              end
            end
          end
        end

        class GraphQLResultArray
          include GraphQLResult

          def initialize(_runtime_inst, _result_name, _result_type, _application_value, _parent_result, _is_non_null_in_parent, _selections, _is_eager, _ast_node, _graphql_arguments, graphql_field) # rubocop:disable Metrics/ParameterLists
            super
            @graphql_result_data = []
          end

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}(#{@graphql_result_type.to_type_signature} @ #{path.join(".")})"
          end

          def depth
            @graphql_depth ||= @graphql_parent.depth + 1
          end

          def step_finished?
            true
          end

          def run_step
            current_type = @graphql_result_type
            inner_type = current_type.of_type
            # This is true for objects, unions, and interfaces
            # use_dataloader_job = !inner_type.unwrap.kind.input?
            idx = nil
            dirs = ast_node.directives
            make_dir_step = !dirs.empty?
            list_value = begin
              begin
                @graphql_application_value.each do |inner_value|
                  idx ||= 0
                  this_idx = idx
                  idx += 1
                  list_item_step = ListItemStep.new(
                    @runtime,
                    self,
                    this_idx,
                    inner_value
                  )
                  @runtime.run_queue.append_step(if make_dir_step
                    ListItemDirectivesStep.new(@runtime, @graphql_application_value, :resolve_each, dirs, list_item_step)
                  else
                    list_item_step
                  end)
                end

                self
              rescue NoMethodError => err
                # Ruby 2.2 doesn't have NoMethodError#receiver, can't check that one in this case. (It's been EOL since 2017.)
                if err.name == :each && (err.respond_to?(:receiver) ? err.receiver == @graphql_application_value : true)
                  # This happens when the GraphQL schema doesn't match the implementation. Help the dev debug.
                  raise ListResultFailedError.new(value: @graphql_application_value, field: @graphql_field, path: @runtime.current_path)
                else
                  # This was some other NoMethodError -- let it bubble to reveal the real error.
                  raise
                end
              rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => ex_err
                ex_err
              rescue StandardError => err
                begin
                  @runtime.query.handle_or_reraise(err)
                rescue GraphQL::ExecutionError => ex_err
                  ex_err
                end
              end
            rescue StandardError => err
              begin
                @runtime.query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
            # Detect whether this error came while calling `.each` (before `idx` is set) or while running list *items* (after `idx` is set)
            error_is_non_null = idx.nil? ? @graphql_is_non_null_in_parent : inner_type.non_null?
            @runtime.continue_value(list_value, @graphql_field, error_is_non_null, @ast_node, @graphql_result_name, @graphql_parent)
          end

          def graphql_skip_at(index)
            # Mark this index as dead. It's tricky because some indices may already be storing
            # `Lazy`s. So the runtime is still holding indexes _before_ skipping,
            # this object has to coordinate incoming writes to account for any already-skipped indices.
            @skip_indices ||= []
            @skip_indices << index
            offset_by = @skip_indices.count { |skipped_idx| skipped_idx < index}
            delete_at_index = index - offset_by
            @graphql_metadata && @graphql_metadata.delete_at(delete_at_index)
            @graphql_result_data.delete_at(delete_at_index)
          end

          def set_leaf(idx, value)
            if @skip_indices
              offset_by = @skip_indices.count { |skipped_idx| skipped_idx < idx }
              idx -= offset_by
            end
            @graphql_result_data[idx] = value
            @graphql_metadata && @graphql_metadata[idx] = value
            value
          end

          def set_child_result(idx, value)
            if @skip_indices
              offset_by = @skip_indices.count { |skipped_idx| skipped_idx < idx }
              idx -= offset_by
            end
            @graphql_result_data[idx] = value.graphql_result_data
            # If we encounter some part of this response that requires metadata tracking,
            # then create the metadata hash if necessary. It will be kept up-to-date after this.
            (@graphql_metadata ||= @graphql_result_data.dup)[idx] = value
            value
          end

          def values
            (@graphql_metadata || @graphql_result_data)
          end

          def [](idx)
            (@graphql_metadata || @graphql_result_data)[idx]
          end
        end
      end
    end
  end
end
