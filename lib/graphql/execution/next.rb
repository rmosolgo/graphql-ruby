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

        attr_reader :steps_queue, :schema, :context, :variables

        def execute
          operation = @document.definitions.first # TODO select named operation
          isolated_steps = case operation.operation_type
          when nil, "query"
            [
              SelectionsStep.new(
                parent_type: @schema.query,
                selections: operation.selections,
                objects: [@root_object],
                results: [@data],
                runner: self,
              )
            ]
          when "mutation"
            fields = {}
            gather_selections(@schema.mutation, operation.selections, into: fields)
            fields.each_value.map do |field_resolve_step|
              SelectionsStep.new(
                parent_type: @schema.mutation,
                selections: field_resolve_step.ast_nodes,
                objects: [@root_object],
                results: [@data],
                runner: self,
              )
            end
          else
            raise ArgumentError, "Unhandled operation type: #{operation.operation_type.inspect}"
          end

          while (next_isolated_step = isolated_steps.shift)
            @steps_queue << next_isolated_step
            while (step = @steps_queue.shift)
              step.execute
            end
          end

          { "data" => @data }
        end

        def gather_selections(type_defn, ast_selections, into:)
          ast_selections.each do |ast_selection|
            case ast_selection
            when GraphQL::Language::Nodes::Field
              key = ast_selection.alias || ast_selection.name
              step = into[key] ||= FieldResolveStep.new(
                parent_type: type_defn,
                runner: self,
              )
              step.append_selection(ast_selection)
            when GraphQL::Language::Nodes::InlineFragment
              type_condition = ast_selection.type.name
              if type_condition_applies?(type_defn, type_condition)
                gather_selections(type_defn, ast_selection.selections, into: into)
              end
            when GraphQL::Language::Nodes::FragmentSpread
              fragment_definition = @document.definitions.find { |defn| defn.is_a?(GraphQL::Language::Nodes::FragmentDefinition) && defn.name == ast_selection.name }
              type_condition = fragment_definition.type.name
              if type_condition_applies?(type_defn, type_condition)
                gather_selections(type_defn, fragment_definition.selections, into: into)
              end
            else
              raise ArgumentError, "Unsupported graphql selection node: #{ast_selection.class} (#{ast_selection.inspect})"
            end
          end
        end

        private

        def type_condition_applies?(concrete_type, type_name)
          if type_name == concrete_type.graphql_name
            true
          else
            abs_t = @schema.get_type(type_name, @context)
            p_types = @schema.possible_types(abs_t, @context)
            p_types.include?(concrete_type)
          end
        end

        class FieldResolveStep
          def initialize(parent_type:, runner:)
            @parent_type = parent_type
            @ast_nodes = []
            @objects = nil
            @results = nil
            @runner = runner
          end

          attr_writer :objects, :results

          attr_reader :ast_nodes

          def append_selection(ast_node)
            @ast_nodes << ast_node
          end

          def coerce_arguments(ast_arguments)
            ast_arguments.each_with_object({}) { |arg_node, obj|
              arg_value = coerce_argument_value(arg_node.value)
              arg_key = Schema::Member::BuildType.underscore(arg_node.name).to_sym
              obj[arg_key] = arg_value
            }
          end

          def coerce_argument_value(arg_value)
            case arg_value
            when String, Numeric, true, false, nil
              arg_value
            when Language::Nodes::VariableIdentifier
              @runner.variables.fetch(arg_value.name)
            when Language::Nodes::InputObject
              coerce_arguments(arg_value.arguments)
            when Language::Nodes::Enum
              arg_value.name
            when Array
              arg_value.map { |v| coerce_argument_value(v) }
            when Language::Nodes::NullValue
              nil
            else
              raise "Unsupported argument value: #{arg_value.class} (#{arg_value.inspect})"
            end
          end

          def execute
            ast_node = @ast_nodes.first
            field_defn = @runner.schema.get_field(@parent_type, ast_node.name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
            result_key = ast_node.alias || ast_node.name

            arguments = coerce_arguments(ast_node.arguments)

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

          def execute
            grouped_selections = {}
            @runner.gather_selections(@parent_type, @selections, into: grouped_selections)
            grouped_selections.each_value do |frs|
              frs.objects = @objects
              frs.results = @results
              @runner.steps_queue << frs
            end
          end
        end
      end
    end
  end
end
