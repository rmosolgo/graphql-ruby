# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter
      class Runtime
        class GraphQLResultArray
          include GraphQLResult

          def initialize(_runtime_inst, _result_name, _result_type, _application_value, _parent_result, _is_non_null_in_parent, _selections, _is_eager, _ast_node, _graphql_arguments, graphql_field) # rubocop:disable Metrics/ParameterLists
            super
            @graphql_result_data = []
          end

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}:#@step(#{@graphql_result_type.to_type_signature} @ #{path.join(".")})"
          end

          def depth
            @graphql_depth ||= @graphql_parent.depth + 1
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
                  @runtime.dataloader.append_job(list_item_step)
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
