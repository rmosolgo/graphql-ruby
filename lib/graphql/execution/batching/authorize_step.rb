# frozen_string_literal: true
module GraphQL
  module Execution
    module Batching
      class AuthorizeStep
        def initialize(static_type:, object:, runner:, graphql_result:, key:, is_non_null:, field_resolve_step:, next_objects:, next_results:)
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
        end

        def value
          if @authorized_value
            @authorized_value = @field_resolve_step.sync(@authorized_value)
          elsif @resolved_type
            @resolved_type = @field_resolve_step.sync(@resolved_type)
          end
          @runner.add_step(self)
        end

        def call
          case @next_step
          when :resolve_type
            @resolved_type, _ignored_value = @static_type.kind.abstract? ? @runner.schema.resolve_type(@static_type, @object, @runner.context) : @static_type
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
        end

        def create_result
          if @authorized_value
            next_result_h = {}
            @next_results << next_result_h
            @next_objects << @object
            @graphql_result[@key] = next_result_h
            @runner.runtime_types_at_result[next_result_h] = @resolved_type
            @runner.static_types_at_result[next_result_h] = @static_type
            @field_resolve_step.authorized_finished
          elsif @is_non_null
            @graphql_result[@key] = @runner.add_non_null_error(@field_result_step.parent_type, @field_result_step.field_definition, @field_result_step.ast_node, is_from_array, @field_resolve_step.path)
          else
            @graphql_result[@key] = nil
          end
        end
      end
    end
  end
end
