# frozen_string_literal: true
module GraphQL
  module Execution
    class Interpreter

      class RunQueue
        def initialize(query)
          @query = query
          @steps = []
        end

        attr_reader :query

        def next(step)
          @steps << step
        end

        def run
          while (step = @steps.shift)
            step.call(self)
          end
          nil
        end
      end

      class ResolveOperationDirectives
        def initialize(object, type, root_operation, response)
          @object = object
          @type = type
          @root_operation = root_operation
          @response = response
        end

        def call(run_queue)
          directives = @root_operation.directives
          if directives.nil? || directives.empty?
            run_queue.next(GatherSelections.new(@object, @type, @root_operation.selections, @response))
          else
            # TODO
            run_directive(method_name, object, directives, 0, &block)
          end
        end
      end

      class GatherSelections
        def initialize(object, type, selections, graphql_response)
          @object = object
          @type = type
          @selections = selections
          @graphql_response = graphql_response
          @runtime_directive_names = [] # todo
        end

        def call(run_queue)
          gathered_selections = gather_selections(run_queue, @object, @type, @selections)
          if gathered_selections.is_a?(Array)
            raise "TODO"
          else
            run_queue.next(EvaluateSelections.new(gathered_selections, @graphql_response, @object))
          end
        end

        private

        def gather_selections(run_queue, owner_object, owner_type, selections, selections_to_run = nil, selections_by_name = {})
          query = run_queue.query
          schema = query.schema
          context = query.context
          selections.each do |node|
            # Skip gathering this if the directive says so
            # if !directives_include?(node, owner_object, owner_type)
            #   next
            # end

            if node.is_a?(GraphQL::Language::Nodes::Field)
              response_key = node.alias || node.name
              selections = selections_by_name[response_key]
              # if there was already a selection of this field,
              # use an array to hold all selections,
              # otherise, use the single node to represent the selection
              if selections
                # This field was already selected at least once,
                # add this node to the list of selections
                s = Array(selections)
                s << node
                selections_by_name[response_key] = s
              else
                # No selection was found for this field yet
                selections_by_name[response_key] = node
              end
            else
              # This is an InlineFragment or a FragmentSpread
              if @runtime_directive_names.any? && node.directives.any? { |d| @runtime_directive_names.include?(d.name) }
                next_selections = {}
                next_selections[:graphql_directives] = node.directives
                if selections_to_run
                  selections_to_run << next_selections
                else
                  selections_to_run = []
                  selections_to_run << selections_by_name
                  selections_to_run << next_selections
                end
              else
                next_selections = selections_by_name
              end

              case node
              when GraphQL::Language::Nodes::InlineFragment
                if node.type
                  type_defn = schema.get_type(node.type.name, context)

                  if query.warden.possible_types(type_defn).include?(owner_type)
                    result = gather_selections(run_queue, owner_object, owner_type, node.selections, selections_to_run, next_selections)
                    if !result.equal?(next_selections)
                      selections_to_run = result
                    end
                  end
                else
                  # it's an untyped fragment, definitely continue
                  result = gather_selections(run_queue, owner_object, owner_type, node.selections, selections_to_run, next_selections)
                  if !result.equal?(next_selections)
                    selections_to_run = result
                  end
                end
              when GraphQL::Language::Nodes::FragmentSpread
                fragment_def = query.fragments[node.name]
                type_defn = query.get_type(fragment_def.type.name)
                if query.warden.possible_types(type_defn).include?(owner_type)
                  result = gather_selections(run_queue, owner_object, owner_type, fragment_def.selections, selections_to_run, next_selections)
                  if !result.equal?(next_selections)
                    selections_to_run = result
                  end
                end
              else
                raise "Invariant: unexpected selection class: #{node.class}"
              end
            end
          end
          selections_to_run || selections_by_name
        end
      end

      class EvaluateSelections
        def initialize(gathered_selections, result, object)
          @gathered_selections = gathered_selections
          @result = result
          @object = object
        end

        def call(run_queue)
          @gathered_selections.each do |result_name, field_ast_nodes_or_ast_node|
            # TODO directives on each selection
            run_queue.next(EvaluateSelection.new(result_name, field_ast_nodes_or_ast_node, @result, @object))
          end
          # run_queue.next(MergeResults)
          # TODO clear cache
        end
      end

      class EvaluateSelection
        def initialize(result_name, field_ast_nodes_or_ast_node, result, object)
          @result_name = result_name
          @field_ast_nodes_or_ast_node = field_ast_nodes_or_ast_node
          @result = result
          @object = object
        end

        def call(run_queue)
          object = @object
          if @field_ast_nodes_or_ast_node.is_a?(Array)
            field_ast_nodes = @field_ast_nodes_or_ast_node
            ast_node = field_ast_nodes.first
          else
            field_ast_nodes = nil
            ast_node = @field_ast_nodes_or_ast_node
          end
          field_name = ast_node.name
          owner_type = @result.graphql_result_type
          field_defn = run_queue.query.warden.get_field(owner_type, field_name)

          # Set this before calling `run_with_directives`, so that the directive can have the latest path
          # runtime_state = get_current_runtime_state
          # runtime_state.current_field = field_defn
          # runtime_state.current_result = @result
          # runtime_state.current_result_name = result_name

          owner_object = @result.graphql_application_value
          if field_defn.dynamic_introspection
            owner_object = field_defn.owner.wrap(owner_object, run_queue.query.context)
          end

          return_type = field_defn.type

          run_queue.query.arguments_cache.dataload_for(ast_node, field_defn, owner_object) do |resolved_arguments|
            # runtime_state = get_current_runtime_state # This might be in a different fiber

            return_type_non_null = return_type.non_null?
            if resolved_arguments.is_a?(GraphQL::ExecutionError) || resolved_arguments.is_a?(GraphQL::UnauthorizedError)
              continue_value(resolved_arguments, field_defn, return_type_non_null, ast_node, result_name, selection_result)
              next
            end

            # TODO extras, NO_ARGS
            kwarg_arguments = resolved_arguments.keyword_arguments

            # runtime_state.current_field = field_defn
            # runtime_state.current_arguments = resolved_arguments
            # runtime_state.current_result_name = result_name
            # runtime_state.current_result = selection_result
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

            begin
              # TODO check directives, reset state
              # Actually call the field resolver and capture the result
              app_result = begin
                # @current_trace.execute_field(field: field_defn, ast_node: ast_node, query: query, object: object, arguments: kwarg_arguments) do
                field_defn.resolve(owner_object, kwarg_arguments, run_queue.query.context)
              rescue GraphQL::ExecutionError => err
                err
              rescue StandardError => err
                begin
                  run_queue.query.handle_or_reraise(err)
                rescue GraphQL::ExecutionError => ex_err
                  ex_err
                end
              end

              run_queue.next(HandleResult.new(app_result, return_type, @result_name, @result, next_selections))
            end
            # If this field is a root mutation field, immediately resolve
            # all of its child fields before moving on to the next root mutation field.
            # (Subselections of this mutation will still be resolved level-by-level.)
            # if is_eager_field
            #   Interpreter::Resolve.resolve_all([field_result], @dataloader)
            # end
          end
        end
      end

      class HandleResult
        def initialize(result_value, result_type, result_name, result, next_selections)
          @result_value = result_value
          @result_type = result_type
          @result_name = result_name
          @result = result
          @next_selections = next_selections
        end

        def call(run_queue)
          next_type_non_null = @result_type.non_null?
          next_type = if next_type_non_null
            @result_type.of_type
          else
            @result_type
          end

          case next_type.kind.name
          when "SCALAR", "ENUM"
            @result.set_leaf(@result_name, @result_value)
          when "UNION", "INTERFACE"
            resolved_type, _resolved_value = run_queue.query.schema.resolve_type(next_type, @result_value, run_queue.query.context)
            run_queue.next(HandleResult.new(@result_value, resolved_type, @result_name, @result, @next_selections))
          when "OBJECT"
            type_obj = next_type.wrap(@result_value, run_queue.query.context)
            response_hash = GraphQL::Execution::Interpreter::Runtime::GraphQLResultHash.new(@result_name, next_type, type_obj, @result, next_type_non_null)
            @result.set_child_result(@result_name, response_hash)
            run_queue.next(GatherSelections.new(type_obj, next_type, @next_selections, response_hash))
          when "LIST"
            response_arr = GraphQL::Execution::Interpreter::Runtime::GraphQLResultArray.new(@result_name, next_type, @result_value, @result, next_type_non_null)
            @result.set_child_result(@result_name, response_arr)
            run_queue.next(EvaluateList.new(response_arr, @result_value, next_type.of_type, @next_selections))
          else
            raise "Unhandled TYPE_KIND #{next_type.kind.name}"
          end
        end
      end

      class EvaluateList
        def initialize(result, list, inner_type, selections)
          @result = result
          @list = list
          @inner_type = inner_type
          @selections = selections
        end

        def call(run_queue)
          @list.each_with_index do |item, idx|
            run_queue.next(HandleResult.new(item, @inner_type, idx, @result, @selections))
          end
        end
      end
    end
  end
end
