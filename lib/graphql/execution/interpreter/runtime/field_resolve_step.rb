# frozen_string_literal: true

module GraphQL
  module Execution
    class Interpreter
      class Runtime
        class FieldResolveStep
          include Runtime::Step

          def initialize(runtime, field, ast_node, ast_nodes, result_name, selection_result)
            @runtime = runtime
            @field = field
            @object = selection_result.graphql_application_value
            if @field.dynamic_introspection
              @object = field.owner.wrap(@object, @runtime.context)
            end
            @ast_node = ast_node
            @ast_nodes = ast_nodes
            @result_name = result_name
            @selection_result = selection_result
            @next_selections = nil
            @step = :inspect_ast
          end

          attr_reader :selection_result

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}/#@step(#{@field.path} @ #{@selection_result.path.join(".")}.#{@result_name})"
          end

          def step_finished?
            @step == :finished
          end

          def depth
            @selection_result.depth + 1
          end

          attr_accessor :result

          def value # Lazy API
            @result = begin
              @runtime.schema.sync_lazy(@result)
            rescue GraphQL::ExecutionError => err
              err
            rescue StandardError => err
              begin
                @runtime.query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
          end

          def run_step
            if @selection_result.graphql_dead
              @step = :finished
              return nil
            end
            case @step
            when :inspect_ast
              inspect_ast
            when :load_arguments
              load_arguments
            when :prepare_kwarg_arguments
              prepare_kwarg_arguments
            when :call_field_resolver
              call_field_resolver
            when :handle_resolved_value
              handle_resolved_value
            else
              raise "Invariant: unexpected #{self.class} step: #{@step.inspect} (#{inspect_step})"
            end
          end

          private

          def inspect_ast
            # Optimize for the case that field is selected only once
            if @ast_nodes.nil? || @ast_nodes.size == 1
              @next_selections = @ast_node.selections
              directives = @ast_node.directives
            else
              @next_selections = []
              directives = []
              @ast_nodes.each { |f|
                @next_selections.concat(f.selections)
                directives.concat(f.directives)
              }
            end

            if directives.any?
              @step = :finished # some way to detect whether the block below is called or not
              @runtime.call_method_on_directives(:resolve, @object, directives) do
                @step = :load_arguments
                self # TODO what kind of compatibility is possible here?
              end
            else
              # TODO some way to continue without this step
              @step = :load_arguments
            end
          end

          def load_arguments
            if !@field.any_arguments?
              @resolved_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
              if @field.extras.size == 0
                @kwarg_arguments = EmptyObjects::EMPTY_HASH
                @step = :call_field_resolver # kwargs are already ready -- they're empty
              else
                @step = :prepare_kwarg_arguments
              end
              nil
            else
              @step = :prepare_kwarg_arguments
              @runtime.query.arguments_cache.dataload_for(@ast_node, @field, @object) do |resolved_arguments|
                @result = resolved_arguments
              end
              @result
            end
          end

          def prepare_kwarg_arguments
            if @resolved_arguments.nil? && @result.nil?
              @runtime.dataloader.run
            end
            @resolved_arguments ||= @result
            @result = nil
            if @resolved_arguments.is_a?(GraphQL::ExecutionError) || @resolved_arguments.is_a?(GraphQL::UnauthorizedError)
              return_type_non_null = @field.type.non_null?
              @runtime.continue_value(@resolved_arguments, @field, return_type_non_null, @ast_node, @result_name, @selection_result)
              @step = :finished
              return
            end

            @kwarg_arguments = if @field.extras.empty?
              if @resolved_arguments.empty?
                # We can avoid allocating the `{ Symbol => Object }` hash in this case
                EmptyObjects::EMPTY_HASH
              else
                @resolved_arguments.keyword_arguments
              end
            else
              # Bundle up the extras, then make a new arguments instance
              # that includes the extras, too.
              extra_args = {}
              @field.extras.each do |extra|
                case extra
                when :ast_node
                  extra_args[:ast_node] = @ast_node
                when :execution_errors
                  extra_args[:execution_errors] = ExecutionErrors.new(@runtime.context, @ast_node, @runtime.current_path)
                when :path
                  extra_args[:path] = @runtime.current_path
                when :lookahead
                  if !@field_ast_nodes
                    @field_ast_nodes = [@ast_node]
                  end

                  extra_args[:lookahead] = Execution::Lookahead.new(
                    query: @runtime.query,
                    ast_nodes: @field_ast_nodes,
                    field: @field,
                  )
                when :argument_details
                  # Use this flag to tell Interpreter::Arguments to add itself
                  # to the keyword args hash _before_ freezing everything.
                  extra_args[:argument_details] = :__arguments_add_self
                when :parent
                  parent_result = @selection_result.graphql_parent
                  if parent_result.is_a?(GraphQL::Execution::Interpreter::Runtime::GraphQLResultArray)
                    parent_result = parent_result.graphql_parent
                  end
                  parent_value = parent_result&.graphql_application_value&.object
                  extra_args[:parent] = parent_value
                else
                  extra_args[extra] = @field.fetch_extra(extra, @runtime.context)
                end
              end
              if !extra_args.empty?
                @resolved_arguments = @resolved_arguments.merge_extras(extra_args)
              end
              @resolved_arguments.keyword_arguments
            end
            @step = :call_field_resolver
            nil
          end

          def call_field_resolver
            # if !directives.empty?
              # This might be executed in a different context; reset this info
            runtime_state = @runtime.get_current_runtime_state
            runtime_state.current_field = @field
            runtime_state.current_arguments = @resolved_arguments
            runtime_state.current_result_name = @result_name
            runtime_state.current_result = @selection_result
            # end

            # Actually call the field resolver and capture the result
            query = @runtime.query
            app_result = begin
              @runtime.current_trace.begin_execute_field(@field, @object, @kwarg_arguments, query)
              @runtime.current_trace.execute_field(field: @field, ast_node: @ast_node, query: query, object: @object, arguments: @kwarg_arguments) do
                @field.resolve(@object, @kwarg_arguments, query.context)
              end
            rescue GraphQL::ExecutionError => err
              err
            rescue StandardError => err
              begin
                query.handle_or_reraise(err)
              rescue GraphQL::ExecutionError => ex_err
                ex_err
              end
            end
            @runtime.current_trace.end_execute_field(@field, @object, @kwarg_arguments, query, app_result)
            @step = :handle_resolved_value
            @result = app_result
          end

          def handle_resolved_value
            runtime_state = @runtime.get_current_runtime_state
            runtime_state.current_field = @field
            runtime_state.current_arguments = @resolved_arguments
            runtime_state.current_result_name = @result_name
            runtime_state.current_result = @selection_result
            return_type = @field.type
            @result = @runtime.continue_value(@result, @field, return_type.non_null?, @ast_node, @result_name, @selection_result)

            if !HALT.equal?(@result)
              runtime_state = @runtime.get_current_runtime_state
              was_scoped = runtime_state.was_authorized_by_scope_items
              runtime_state.was_authorized_by_scope_items = nil
              @runtime.continue_field(@result, @field, return_type, @ast_node, @next_selections, false, @resolved_arguments, @result_name, @selection_result, was_scoped, runtime_state)
            else
              nil
            end
            @step = :finished
            nil
          end
        end
      end
    end
  end
end
