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

        attr_reader :steps_queue, :schema, :context

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

            arguments = ast_node.arguments.each_with_object({}) { |arg_node, obj| obj[arg_node.name.to_sym] = arg_node.value }

            field_results = if arguments.empty?
              field_defn.resolve_all(@objects, @runner.context)
            else
              field_defn.resolve_all(@objects, @runner.context, **arguments)
            end

            return_type = field_defn.type
            return_result_type = return_type.unwrap
            if return_result_type.kind.composite?
              next_selections = [] # TODO optimize for one ast node
              @ast_nodes.each do |ast_node|
                next_selections.concat(ast_node.selections)
              end
              if return_type.list?
                all_next_objects = []
                all_next_results = []
                field_results.each_with_index do |result_arr, i|
                  next_results = Array.new(result_arr.length) { Hash.new }
                  result_h = @results[i]
                  result_h[result_key] = next_results
                  all_next_objects.concat(result_arr)
                  all_next_results.concat(next_results)
                end
                @runner.steps_queue << SelectionsStep.new(
                  parent_type: return_result_type,
                  selections: next_selections,
                  objects: all_next_objects,
                  results: all_next_results,
                  runner: @runner,
                )
              else
                next_results = nil

                field_results.each_with_index do |result, i|
                  result_h = @results[i]
                  if result.nil?
                    result_h[result_key] = nil
                  else
                    next_results ||= []
                    next_results << result_h[result_key] = {}
                  end
                end

                if next_results
                  @runner.steps_queue << SelectionsStep.new(
                    parent_type: return_result_type,
                    selections: next_selections,
                    objects: field_results,
                    results: next_results,
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
            @selections.each do |ast_selection|
              case ast_selection
              when GraphQL::Language::Nodes::Field
                key = ast_selection.alias || ast_selection.name
                step = grouped_selections[key] ||= begin
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
