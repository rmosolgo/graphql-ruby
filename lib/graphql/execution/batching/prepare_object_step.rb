# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class PrepareObjectStep
        def initialize(static_type:, object:, runner:, graphql_result:, key:, is_non_null:, field_resolve_step:, next_objects:, next_results:, is_from_array:)
          @static_type = static_type
          @object = object
          @runner = runner
          @field_resolve_step = field_resolve_step
          @is_non_null = is_non_null
          @next_objects = next_objects
          @next_results = next_results
          @graphql_result = graphql_result
          @resolved_type = nil
          @authorized_value = nil
          @key = key
          @next_step = :resolve_type
          @is_from_array = is_from_array
        end

        def value
          if @authorized_value
            @authorized_value = @field_resolve_step.sync(@authorized_value)
          elsif @resolved_type
            @resolved_type, _ignored_value = @field_resolve_step.sync(@resolved_type)
          end
          @runner.add_step(self)
        end

        def call
          case @next_step
          when :resolve_type
            if @static_type.kind.abstract?
              @resolved_type, _ignored_value = @runner.schema.resolve_type(@static_type, @object, @runner.context)
            else
              @resolved_type = @static_type
            end
            if @runner.resolves_lazies && @runner.schema.lazy?(@resolved_type)
              @next_step = :authorize
              @runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
            else
              authorize
            end
          when :authorize
            authorize
          when :create_result
            create_result
          else
            raise ArgumentError, "This is a bug, unknown step: #{@next_step.inspect}"
          end
        end

        def authorize
          @authorized_value = @resolved_type.authorized?(@object, @runner.context)
          if @runner.resolves_lazies && @runner.schema.lazy?(@authorized_value)
            @runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
            @next_step = :create_result
          else
            create_result
          end
        rescue GraphQL::Error => err
          err.path = @field_resolve_step.path
          err.ast_nodes = @field_resolve_step.ast_nodes
          @runner.context.errors << err
          @graphql_result[@key] = err
        end

        def create_result
          if @authorized_value
            next_result_h = {}
            @next_results << next_result_h
            @next_objects << @object
            @graphql_result[@key] = next_result_h
            @runner.runtime_types_at_result[next_result_h] = @resolved_type
            @runner.static_types_at_result[next_result_h] = @static_type
          elsif @is_non_null
            @graphql_result[@key] = @field_resolve_step.add_non_null_error(@is_from_array)
          else
            @graphql_result[@key] = nil
          end

          @field_resolve_step.authorized_finished
        end
      end
    end
  end
end
