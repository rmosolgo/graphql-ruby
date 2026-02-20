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
          @authorization_error = nil
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
              @resolved_type, _ignored_value = @runner.schema.resolve_type(@static_type, @object, @field_resolve_step.selections_step.query.context)
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
          ctx = @field_resolve_step.selections_step.query.context
          begin
            @authorized_value = @resolved_type.authorized?(@object, ctx)
          rescue GraphQL::UnauthorizedError => auth_err
            @authorization_error = auth_err
          end

          if @runner.resolves_lazies && @runner.schema.lazy?(@authorized_value)
            @runner.dataloader.lazy_at_depth(@field_resolve_step.path.size, self)
            @next_step = :create_result
          else
            create_result
          end
        rescue GraphQL::Error => err
          @graphql_result[@key] = @field_resolve_step.add_graphql_error(err)
        end

        def create_result
          if !@authorized_value
            @authorization_error ||= GraphQL::UnauthorizedError.new(object: @object, type: @resolved_type, context: @field_resolve_step.selections_step.query.context)
          end

          if @authorization_error
            begin
              new_obj = @runner.schema.unauthorized_object(@authorization_error)
              if new_obj
                @authorized_value = true
                @object = new_obj
              elsif @is_non_null
                @graphql_result[@key] = @field_resolve_step.add_non_null_error(@is_from_array)
              else
                @graphql_result[@key] = @field_resolve_step.add_graphql_error(@authorization_error)
              end
            rescue GraphQL::Error => err
              if @is_non_null
                @graphql_result[@key] = @field_resolve_step.add_non_null_error(@is_from_array)
              else
                @graphql_result[@key] = @field_resolve_step.add_graphql_error(err)
              end
            end
          end

          if @authorized_value
            next_result_h = {}
            @next_results << next_result_h
            @next_objects << @object
            @graphql_result[@key] = next_result_h
            @runner.runtime_types_at_result[next_result_h] = @resolved_type
            @runner.static_types_at_result[next_result_h] = @static_type
          end

          @field_resolve_step.authorized_finished
        end
      end
    end
  end
end
