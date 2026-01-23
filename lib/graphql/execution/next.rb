# frozen_string_literal: true
module GraphQL
  module Execution
    module Next
      def self.run(schema:, query_string:, context:, variables:, root_object:)

        document = GraphQL.parse(query_string)
        validation_errors = schema.validate(document, context: context)
        if !validation_errors.empty?
          return {
            "errors" => validation_errors.map(&:to_h)
          }
        end
        dummy_q = GraphQL::Query.new(schema, document: document, context: context, variables: variables, root_value: root_object)
        query_context = dummy_q.context

        runner = Runner.new(schema, document, query_context, variables, root_object)
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
            next if !directives_include?(ast_selection)
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

        def directives_include?(ast_selection)
          if ast_selection.directives.any? { |dir_node|
                (dir_node.name == "skip" && dir_node.arguments.any? { |arg_node| arg_node.name == "if" && arg_node.value == true }) || # rubocop:disable Development/ContextIsPassedCop
                (dir_node.name == "include" && dir_node.arguments.any? { |arg_node| arg_node.name == "if" && arg_node.value == false }) # rubocop:disable Development/ContextIsPassedCop
              }
            false
          else
            true
          end
        end

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

          def coerce_arguments(argument_owner, ast_arguments_or_hash)
            arg_defns = argument_owner.arguments(@runner.context)
            args_hash = {}
            if ast_arguments_or_hash.is_a?(Hash)
              ast_arguments_or_hash.each do |key, value|
                arg_defn = arg_defns.each_value.find { |a| a.keyword == key }
                arg_value = coerce_argument_value(arg_defn.type, value)
                args_hash[key] = arg_value
              end
            else
              ast_arguments_or_hash.each { |arg_node|
                arg_defn = arg_defns[arg_node.name]
                arg_value = coerce_argument_value(arg_defn.type, arg_node.value)
                arg_key = Schema::Member::BuildType.underscore(arg_node.name).to_sym
                args_hash[arg_key] = arg_value
              }
            end

            arg_defns.each do |arg_graphql_name, arg_defn|
              if arg_defn.default_value? && !args_hash.key?(arg_defn.keyword)
                args_hash[arg_defn.keyword] = arg_defn.default_value
              end
            end

            args_hash
          end

          def coerce_argument_value(arg_t, arg_value)
            if arg_t.non_null?
              arg_t = arg_t.of_type
            end

            if arg_value.is_a?(Language::Nodes::VariableIdentifier)
              arg_value = if @runner.variables.key?(arg_value.name)
                @runner.variables[arg_value.name]
              elsif @runner.variables.key?(arg_value.name.to_sym)
                @runner.variables[arg_value.name.to_sym]
              end
            elsif arg_value.is_a?(Language::Nodes::NullValue)
              arg_value = nil
            elsif arg_value.is_a?(Language::Nodes::Enum)
              arg_value = arg_value.name
            elsif arg_value.is_a?(Language::Nodes::InputObject)
              arg_value = arg_value.arguments # rubocop:disable Development/ContextIsPassedCop
            end

            if arg_t.list?
              arg_value = Array(arg_value)
              inner_t = arg_t.of_type
              arg_value.map { |v| coerce_argument_value(inner_t, v) }
            elsif arg_t.kind.leaf?
              arg_t.coerce_input(arg_value, @runner.context)
            elsif arg_t.kind.input_object?
              coerce_arguments(arg_t, arg_value)
            else
              raise "Unsupported argument value: #{arg_t.to_type_signature} / #{arg_value.class} (#{arg_value.inspect})"
            end
          end

          def execute
            ast_node = @ast_nodes.first
            field_defn = @runner.schema.get_field(@parent_type, ast_node.name) || raise("Invariant: no field found for #{@parent_type.to_type_signature}.#{ast_node.name}")
            result_key = ast_node.alias || ast_node.name

            arguments = coerce_arguments(field_defn, ast_node.arguments)

            field_objs = if field_defn.dynamic_introspection
              @objects.map { |o| @parent_type.scoped_new(o, @runner.context) }
            else
              @objects
            end
            field_results = if arguments.empty?
              field_defn.resolve_all(field_objs, @runner.context)
            else
              field_defn.resolve_all(field_objs, @runner.context, **arguments)
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
                  all_next_objects << result
                end
                result_h[result_key] = next_results
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
              return_type = field_defn.type
              field_results.each_with_index do |result, i|
                result_h = @results[i] || raise("Invariant: no result object at index #{i} for #{@parent_type.to_type_signature}.#{@ast_node.name} (result: #{result.inspect})")
                if !result.nil?
                  result = return_type.coerce_result(result, @runner.context)
                end
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


      module FieldCompatibility
        def resolve_all(objects, context, **kwargs)
          if @owner.method_defined?(@method_sym)
            # Terrible perf but might work
            objects.map { |o|
              obj_inst = @owner.scoped_new(o, context)
              if kwargs.empty?
                obj_inst.public_send(@method_sym)
              else
                obj_inst.public_send(@method_sym, **kwargs)
              end
            }
          else
            objects.map { |o| o.public_send(@method_sym) }
          end
        end
      end

      GraphQL::Schema::Field.include(FieldCompatibility)
    end
  end
end
