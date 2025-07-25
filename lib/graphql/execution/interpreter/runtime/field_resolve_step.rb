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
              # TODO `.wrap` isn't used elsewhere
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

          def current_result
            @selection_result
          end

          def current_result_name
            @result_name
          end

          def inspect_step
            "#{self.class.name.split("::").last}##{object_id}/#@step(#{@field.path} @ #{@selection_result.path.join(".")}.#{@result_name}, #{@result.class})"
          end

          def depth
            @selection_result.depth + 1
          end

          attr_accessor :result

          def value # Lazy API
            @result = begin
              rs = @runtime.get_current_runtime_state
              rs.current_result = current_result
              rs.current_result_name = current_result_name
              rs.current_step = self
              puts "sync_lazy #{@result} #{inspect_step}"
              @runtime.schema.sync_lazy(@result)
            rescue GraphQL::ExecutionError => err
              err
            rescue UnauthorizedError => err
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
            puts "run_step #{inspect_step}"
            if @selection_result.graphql_dead
              return
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
              @runtime.call_method_on_directives(:resolve, @object, directives) do
                load_arguments
              end
            else
              load_arguments
            end
          end

          def load_arguments
            if !@field.any_arguments?
              @resolved_arguments = GraphQL::Execution::Interpreter::Arguments::EMPTY
              if @field.extras.size == 0
                @kwarg_arguments = EmptyObjects::EMPTY_HASH
                call_field_resolver
              else
                prepare_kwarg_arguments
              end
            else
              @step = :prepare_kwarg_arguments
              @result = nil
              dataload_for_result = @runtime.query.arguments_cache.dataload_for(@ast_node, @field, @object) do |resolved_arguments|
                @result = resolved_arguments
              end
              if (@result && reenqueue_if_lazy?(@result)) || (reenqueue_if_lazy?(dataload_for_result))
                return
              else
                @runtime.steps_to_rerun_after_lazy << self
              end
            end
          end

          def prepare_kwarg_arguments
            # TODO the problem is that if Dataloader pauses in the block above,
            # the step is somehow resumed here.
            # Then the call in the block above also runs later, resulting in double-execution.
            # I think the big fix is to move the dataloader-y stuff from argument resolution
            # and inline it here.
            # @resolved_arguments may have been eagerly set if there aren't actually any args
            # if @resolved_arguments.nil? && @result.nil?
            #   @runtime.dataloader.run
            # end
            @resolved_arguments ||= @result
            @result = nil # TODO is this still necessary?
            if @resolved_arguments.is_a?(GraphQL::ExecutionError) || @resolved_arguments.is_a?(GraphQL::UnauthorizedError)
              return_type_non_null = @field.type.non_null?
              @runtime.continue_value(@resolved_arguments, @field, return_type_non_null, @ast_node, @result_name, @selection_result)
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
            call_field_resolver
          end

          def call_field_resolver
            # if !directives.empty?
              # This might be executed in a different context; reset this info
            runtime_state = @runtime.get_current_runtime_state
            runtime_state.current_field = @field
            runtime_state.current_arguments = @resolved_arguments
            runtime_state.current_result_name = @result_name
            runtime_state.current_result = @selection_result
            runtime_state.current_step = self
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
            @result = app_result
            reenc = reenqueue_if_lazy?(@result)
            p [:app_result, @result, reenc]
            if reenc
              @step = :handle_resolved_value
              return
            else
              handle_resolved_value
            end
          end

          def handle_resolved_value
            return_type = @field.type
            @result = @runtime.continue_value(@result, @field, return_type.non_null?, @ast_node, @result_name, @selection_result)

            if !HALT.equal?(@result)
              runtime_state = @runtime.get_current_runtime_state
              was_scoped =  @was_scoped
              @runtime.continue_field(@result, @field, return_type, @ast_node, @next_selections, false, @resolved_arguments, @result_name, @selection_result, was_scoped, runtime_state)
            end
          end
        end
      end
    end
  end
end
