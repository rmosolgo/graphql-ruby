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
          def initialize(ast_node:, parent_type:, objects:, results:, runner:)
            @parent_type = parent_type
            @ast_node = ast_node
            @objects = objects
            @results = results
            @runner = runner
          end


          def execute
            field_defn = @runner.schema.get_field(@parent_type, @ast_node.name)
            result_key = @ast_node.alias || @ast_node.name
            field_results = field_defn.resolve_all(@objects, @runner.context) # Todo arguments here
            field_results.each_with_index do |result, i|
              @results[i][result_key] = result
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
            @selections.each do |ast_selection|
              case ast_selection
              when GraphQL::Language::Nodes::Field
                runner.steps_queue << FieldResolveStep.new(
                  ast_node: ast_selection,
                  parent_type: @parent_type,
                  objects: @objects,
                  results: @results,
                  runner: @runner,
                )
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
