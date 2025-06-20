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
          end

          def run
            @runtime.each_gathered_selections(self) do |gathered_selections, is_selection_array, ordered_result_keys|
              @ordered_result_keys ||= ordered_result_keys
              if is_selection_array
                selections_result = GraphQLResultHash.new(
                  @graphql_response_name,
                  @graphql_result_type,
                  @graphql_application_value,
                  @graphql_parent,
                  @graphql_is_non_null_in_parent,
                  gathered_selections,
                  false,
                  @ast_node,
                  @graphql_arguments,
                  @graphql_field)
                selections_result.ordered_result_keys = ordered_result_keys
                target_result = self
              else
                selections_result = self
                target_result = nil
              end
              runtime_state = @runtime.get_current_runtime_state
              runtime_state.current_result_name = nil
              runtime_state.current_result = selections_result
              # This is a less-frequent case; use a fast check since it's often not there.
              if (directives = gathered_selections[:graphql_directives])
                gathered_selections.delete(:graphql_directives)
              end

              @runtime.call_method_on_directives(:resolve, selections_result.graphql_application_value, directives) do
                finished_jobs = 0
                enqueued_jobs = gathered_selections.size
                gathered_selections.each do |result_name, field_ast_nodes_or_ast_node|
                  # Field resolution may pause the fiber,
                  # so it wouldn't get to the `Resolve` call that happens below.
                  # So instead trigger a run from this outer context.
                  if selections_result.graphql_is_eager
                    @runtime.dataloader.clear_cache
                    @runtime.dataloader.run_isolated {
                      @runtime.evaluate_selection(
                        result_name, field_ast_nodes_or_ast_node, selections_result
                      )
                      finished_jobs += 1
                      if finished_jobs == enqueued_jobs
                        if target_result
                          selections_result.merge_into(target_result)
                        end
                      end
                      @runtime.dataloader.clear_cache
                    }
                  else
                    @runtime.dataloader.append_job {
                      @runtime.evaluate_selection(
                        result_name, field_ast_nodes_or_ast_node, selections_result
                      )
                      finished_jobs += 1
                      if finished_jobs == enqueued_jobs
                        if target_result
                          selections_result.merge_into(target_result)
                        end
                      end
                    }
                  end
                end
              end
            end
          end


          attr_accessor :ordered_result_keys

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

          def run
            current_type = @graphql_result_type
            inner_type = current_type.of_type
            # This is true for objects, unions, and interfaces
            # use_dataloader_job = !inner_type.unwrap.kind.input?
            inner_type_non_null = inner_type.non_null?
            idx = nil
            rts = @runtime.get_current_runtime_state
            list_value = begin
              begin
                @graphql_application_value.each do |inner_value|
                  idx ||= 0
                  this_idx = idx
                  idx += 1
                  # TODO if use_dataloader_job ...  ??
                  # Better would be to extract a ListValueStep?
                  @runtime.resolve_list_item(
                    inner_value,
                    inner_type,
                    inner_type_non_null,
                    @ast_node,
                    @graphql_field,
                    @graphql_application_value,
                    @graphql_arguments,
                    this_idx,
                    self,
                    @was_scoped, # TODO
                    rts,
                  )
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
