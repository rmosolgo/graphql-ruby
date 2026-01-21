# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
      def self.run(schema:, query_string:, context:, variables:, root_object:)

        document = GraphQL.parse(query_string)
        runner = Runner.new(schema, document, context, variables, root_object)
        runner.execute
      end


      class Runner
        def initialize(schema, document, context, variables, root_object)
          @schema = schema
          @document = document
          @context = context
          @variables = variables
          @root_object = root_object
          @steps_queue = []
          @data = {}
        end

        attr_reader :steps_queue, :schema, :context, :document, :variables

        def execute
          operation = @document.definitions.first # TODO select named operation
          root_type = case operation.operation_type
          when nil, "query"
            @schema.query
          else
            raise ArgumentError, "Unhandled operation type: #{operation.operation_type.inspect}"
          end

          @steps_queue << SelectionsStep.new(
            parent_type: root_type,
            selections: operation.selections,
            objects: [@root_object],
            results: [@data],
            runner: self,
          )

          while (next_step = @steps_queue.shift)
            next_step.execute
          end

          { "data" => @data }
        end

        class FieldResolveStep
          def initialize(parent_type:, objects:, results:, runner:)
            @parent_type = parent_type
            @ast_nodes = []
            @objects = objects
            @results = results
            @runner = runner
          end

          def append_selection(ast_node)
            @ast_nodes << ast_node
          end

          def execute
            ast_node = @ast_nodes.first
            field_defn = @runner.schema.get_field(@parent_type, ast_node.name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
            result_key = ast_node.alias || ast_node.name

            arguments = ast_node.arguments.each_with_object({}) { |arg_node, obj|
              arg_value = arg_node.value
              if arg_value.is_a?(Language::Nodes::VariableIdentifier)
                arg_value = @runner.variables.fetch(arg_value.name)
              end

              obj[arg_node.name.to_sym] = arg_value
            }

            field_results = if arguments.empty?
              field_defn.resolve_all(@objects, @runner.context)
            else
              field_defn.resolve_all(@objects, @runner.context, **arguments)
            end

            return_type = field_defn.type
            return_result_type = return_type.unwrap
            if return_result_type.kind.composite?
              if @ast_nodes.size == 1
                next_selections = @ast_nodes.first.selections
              else
                next_selections = []
                @ast_nodes.each do |ast_node|
                  next_selections.concat(ast_node.selections)
                end
              end

              all_next_objects = []
              all_next_results = []
              is_list = return_type.list?

              field_results.each_with_index do |result, i|
                result_h = @results[i]
                if result.nil?
                  result_h[result_key] = nil
                  next
                elsif is_list
                  next_results = Array.new(result.length) { Hash.new }
                  all_next_objects.concat(result)
                  all_next_results.concat(next_results)
                else
                  next_results = {}
                  all_next_results << next_results
                end
                result_h[result_key] = next_results
              end

              if !is_list && !all_next_results.empty?
                all_next_objects.concat(field_results)
              end

              if !all_next_results.empty?
                if return_result_type.kind.abstract?
                  next_objects_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
                  next_results_by_type = Hash.new { |h, obj_t| h[obj_t] = [] }.compare_by_identity
                  all_next_objects.each_with_index do |next_object, i|
                    object_type, _ignored_new_value = @runner.schema.resolve_type(return_result_type, next_object, @runner.context)
                    next_objects_by_type[object_type] << next_object
                    next_results_by_type[object_type] << all_next_results[i]
                  end

                  next_objects_by_type.each do |obj_type, next_objects|
                    @runner.steps_queue << SelectionsStep.new(
                      parent_type: obj_type,
                      selections: next_selections,
                      objects: next_objects,
                      results: next_results_by_type[obj_type],
                      runner: @runner,
                    )
                  end
                else
                  @runner.steps_queue << SelectionsStep.new(
                    parent_type: return_result_type,
                    selections: next_selections,
                    objects: all_next_objects,
                    results: all_next_results,
                    runner: @runner,
                  )
                end
              end
            else
              field_results.each_with_index do |result, i|
                result_h = @results[i] || raise("Invariant: no result object at index #{i} for #{@parent_type.to_type_signature}.#{@ast_node.name} (result: #{result.inspect})")
                result_h[result_key] = result
              end
            end
          end
        end

        class SelectionsStep
          def initialize(parent_type:, selections:, objects:, results:, runner:)
            @parent_type = parent_type
            @selections = selections
            @objects = objects
            @results = results
            @runner = runner
          end

          attr_reader :runner

          def execute
            grouped_selections = {}
            gather_selections(@selections, into: grouped_selections)
          end

          private

          def type_condition_applies?(type_name)
            if type_name == @parent_type.graphql_name
              true
            else
              abs_t = @runner.schema.get_type(type_name, @runner.context)
              p_types = @runner.schema.possible_types(abs_t, @runner.context)
              p_types.include?(@parent_type)
            end
          end

          def gather_selections(ast_selections, into:)
            ast_selections.each do |ast_selection|
              case ast_selection
              when GraphQL::Language::Nodes::Field
                key = ast_selection.alias || ast_selection.name
                step = into[key] ||= begin
                  frs = FieldResolveStep.new(
                    parent_type: @parent_type,
                    objects: @objects,
                    results: @results,
                    runner: @runner,
                  )
                  runner.steps_queue << frs
                  frs
                end
                step.append_selection(ast_selection)
              when GraphQL::Language::Nodes::InlineFragment
                type_condition = ast_selection.type.name
                if type_condition_applies?(type_condition)
                  gather_selections(ast_selection.selections, into: into)
                end
              when GraphQL::Language::Nodes::FragmentSpread
                fragment_definition = @runner.document.definitions.find { |defn| defn.is_a?(GraphQL::Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
                type_condition = fragment_definition.type.name
                if type_condition_applies?(type_condition)
                  gather_selections(fragment_definition.selections, into: into)
                end
              else
                raise ArgumentError, "Unsupported graphql selection node: #{ast_selection.class} (#{ast_selection.inspect})"
              end
            end
          end
        end
      end
    end
  end
end
