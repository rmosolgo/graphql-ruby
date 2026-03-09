# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
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
            query = @field_resolve_step.selections_step.query
            query.current_trace.begin_authorized(@resolved_type, @object, query.context)
            @authorized_value = @field_resolve_step.sync(@authorized_value)
            query.current_trace.end_authorized(@resolved_type, @object, query.context, @authorized_value)
          elsif @resolved_type
            ctx = @field_resolve_step.selections_step.query.context
            ctx.query.current_trace.begin_resolve_type(@static_type, @object, ctx)
            @resolved_type, _ignored_value = @field_resolve_step.sync(@resolved_type)
            ctx.query.current_trace.end_resolve_type(@static_type, @object, ctx, @resolved_type)
          end
          @runner.add_step(self)
        end

        def call
          case @next_step
          when :resolve_type
            if @static_type.kind.abstract?
              ctx = @field_resolve_step.selections_step.query.context
              ctx.query.current_trace.begin_resolve_type(@static_type, @object, ctx)
              @resolved_type, _ignored_value = @runner.schema.resolve_type(@static_type, @object, ctx)
              ctx.query.current_trace.end_resolve_type(@static_type, @object, ctx, @resolved_type)
            else
              @resolved_type = @static_type
            end
            if @runner.resolves_lazies && @runner.lazy?(@resolved_type)
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
          if @field_resolve_step.was_scoped && !@resolved_type.reauthorize_scoped_objects
            @authorized_value = @object
            create_result
            return
          end

          query = @field_resolve_step.selections_step.query
          begin
            query.current_trace.begin_authorized(@resolved_type, @object, query.context)
            @authorized_value = @resolved_type.authorized?(@object, query.context)
            query.current_trace.end_authorized(@resolve_type, @object, query.context, @authorized_value)
          rescue GraphQL::UnauthorizedError => auth_err
            @authorization_error = auth_err
          end

          if @runner.resolves_lazies && @runner.lazy?(@authorized_value)
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
            @runner.runtime_type_at[next_result_h] = @resolved_type
            @runner.static_type_at[next_result_h] = @static_type
          end

          @field_resolve_step.authorized_finished(self)
        end
      end
    end
  end
end
