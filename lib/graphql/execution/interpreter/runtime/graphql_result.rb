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
            @resolve_type_result = nil
            @authorized_check_result = nil
            if @graphql_result_type.kind.object?
              @step = :authorize_application_value
            else
              @step = :resolve_abstract_type
            end
          end

          def set_step(new_step)
            @step = new_step
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
            @step == :finished
          end

          def value
            if @resolve_type_result
              @resolve_type_result = @runtime.schema.sync_lazy(@resolve_type_result)
            elsif @authorized_check_result
              @runtime.current_trace.begin_authorized(@graphql_result_type, @graphql_application_value, @runtime.context)
              @runtime.current_trace.authorized_lazy(query: @runtime.query, type: @graphql_result_type, object: @graphql_application_value) do
                @authorized_check_result = @runtime.schema.sync_lazy(@authorized_check_result)
                @runtime.current_trace.end_authorized(@graphql_result_type, @graphql_application_value, @runtime.context, @authorized_check_result)
              end
            else
              @graphql_application_value = @runtime.schema.sync_lazy(@graphql_application_value)
            end
          end

          def resolve_abstract_type
            current_type = @graphql_result_type
            value = @graphql_application_value
            @resolve_type_result = begin
              @runtime.resolve_type(current_type, value)
            rescue GraphQL::ExecutionError, GraphQL::UnauthorizedError => ex_err
              return @runtime.continue_value(ex_err, @graphql_field, @graphql_is_non_null_in_parent, @ast_node, @graphql_result_name, @graphql_parent)
            rescue StandardError => err
              begin
                @runtime.query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                return @runtime.continue_value(ex_err, @graphql_field, @graphql_is_non_null_in_parent, @ast_node, @graphql_result_name, @graphql_parent)
              end
            end
          end

          def handle_resolved_type
            if @resolve_type_result.is_a?(Array) && @resolve_type_result.length == 2
              resolved_type, resolved_value = @resolve_type_result
            else
              resolved_type = @resolve_type_result
              resolved_value = value
            end
            @resolve_type_result = nil
            current_type = @graphql_result_type
            possible_types = @runtime.query.types.possible_types(current_type)
            if !possible_types.include?(resolved_type)
              field = @graphql_field
              parent_type = field.owner_type
              err_class = current_type::UnresolvedTypeError
              type_error = err_class.new(resolved_value, field, parent_type, resolved_type, possible_types)
              @runtime.schema.type_error(type_error, @runtime.context)
              @runtime.set_result(self, @result_name, nil, false, is_non_null)
              nil
            else
              @graphql_result_type = resolved_type
            end
          end

          def wrap_application_value
            @graphql_application_value = begin
              value = @graphql_application_value
              context = @runtime.context
              @was_scoped ? @graphql_result_type.wrap_scoped(value, context) : @graphql_result_type.wrap(value, context)
            rescue GraphQL::ExecutionError => err
              err
            end
            @step = :handle_wrapped_application_value
            @graphql_application_value
          end

          def authorize_application_value
            @runtime.current_trace.begin_authorized(@graphql_result_type, @graphql_application_value, @runtime.context)
            begin
              @authorized_check_result = @runtime.current_trace.authorized(query: @runtime.query, type: @graphql_result_type, object: @graphql_application_value) do
                begin
                  @graphql_result_type.authorized?(@graphql_application_value, @runtime.context)
                rescue GraphQL::UnauthorizedError => err
                  @runtime.schema.unauthorized_object(err)
                rescue StandardError => err
                  @runtime.query.handle_or_reraise(err)
                end
              end
            ensure
              @step = :handle_authorized_application_value
              @runtime.current_trace.end_authorized(@graphql_result_type, @graphql_application_value, @runtime.context, @authorized_check_result)
            end
          end

          def run_step
            case @step
            when :resolve_abstract_type
              @step = :handle_resolved_type
              resolve_abstract_type
            when :handle_resolved_type
              handle_resolved_type
              authorize_application_value
            when :authorize_application_value
              # TODO skip if scoped
              authorize_application_value
            when :handle_authorized_application_value
              # TODO doesn't actually support `.wrap`
              if @authorized_check_result
                # TODO don't call `scoped_new here`
                @graphql_application_value = @graphql_result_type.scoped_new(@graphql_application_value, @runtime.context)
              else
                # It failed the authorization check, so go to the schema's authorized object hook
                err = GraphQL::UnauthorizedError.new(object: @graphql_application_value, type: @graphql_result_type, context: @runtime.context)
                # If a new value was returned, wrap that instead of the original value
                begin
                  new_obj = @runtime.schema.unauthorized_object(err)
                  if new_obj
                    # TODO don't do this work-around
                    @graphql_application_value = @graphql_result_type.scoped_new(new_obj, @runtime.context)
                  else
                    @graphql_application_value = nil
                  end
                end
              end
              @authorized_check_result = nil
              @step = :handle_wrapped_application_value
            when :handle_wrapped_application_value
              @graphql_application_value = @runtime.continue_value(@graphql_application_value, @graphql_field, @graphql_is_non_null_in_parent, @ast_node, @graphql_result_name, @graphql_parent)
              if HALT.equal?(@graphql_application_value)
                @step = :finished
                return
              elsif @graphql_parent
                @runtime.set_result(@graphql_parent, @graphql_result_name, self, true, @graphql_is_non_null_in_parent)
              end
              @step = :run_selections
            when :run_selections
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
                  selections_result.set_step :run_selection_directives
                  @runtime.run_queue.append_step(selections_result)
                  @step = :finished # Continuing from others now -- could actually reuse this instance for the first one tho
                else
                  selections_result = self
                  @target_result = nil
                  @graphql_selections = gathered_selections
                  # TODO extract these substeps out into methods, call that method directly
                  @step = :run_selection_directives
                end
                runtime_state = @runtime.get_current_runtime_state
                runtime_state.current_result_name = nil
                runtime_state.current_result = selections_result
                nil
              end
            when :run_selection_directives
              if (directives = @graphql_selections[:graphql_directives])
                @graphql_selections.delete(:graphql_directives)
                @step = :finished # some way to detect whether the block below is called or not
                @runtime.call_method_on_directives(:resolve, @graphql_application_value, directives) do
                  @step = :call_each_field
                end
              else
                # TODO some way to continue without this step
                @step = :call_each_field
              end
            when :call_each_field
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

              if @target_result
                self.merge_into(@target_result)
              end
              @step = :finished
            else
              raise "Invariant: invalid state for #{self.class}: #{@step}"
            end
          end

          def evaluate_selection(result_name, field_ast_nodes_or_ast_node) # rubocop:disable Metrics/ParameterLists
            return if @graphql_dead

            # Don't create the list of nodes if there's only one node
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

            resolve_field_step = FieldResolveStep.new(@runtime, field_defn, ast_node, field_ast_nodes, result_name, self)
            @runtime.run_queue.append_step(resolve_field_step)
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
                    inner_value,
                  )
                  @runtime.run_queue.append_step(list_item_step)
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
