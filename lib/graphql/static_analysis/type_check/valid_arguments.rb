module GraphQL
  module StaticAnalysis
    class TypeCheck
      module ValidArguments
        module_function
        # Analyze either:
        # - The literal value
        # - The variable usage (based on variable definition in the operation)
        # @return [Array<AnalysisError>] Any errors found for this argument
        def errors_for_argument(schema, variable_usages, dependencies, root_node, parent_defn, argument_defn, argument_node)
          errors = []
          case argument_node.value
          when GraphQL::Language::Nodes::VariableIdentifier
            variable_name = argument_node.value.name
            variable_definitions = variable_definitions_for_op_defn(variable_usages, dependencies, root_node, variable_name)
            variable_definitions.each do |variable_definition|
              variable_type = schema.type_from_ast(variable_definition.type)
              argument_type = argument_defn.type
              type_comparison_error = TypeCheck::TypeComparison.compare_inputs(argument_type, variable_type, has_default: !variable_definition.default_value.nil?)
              case type_comparison_error
              when TypeComparison::TYPE_MISMATCH
                errors << create_error("Type mismatch", variable_type, variable_definition, argument_type, argument_node)
              when TypeComparison::LIST_MISMATCH
                errors << create_error("List dimension mismatch", variable_type, variable_definition, argument_type, argument_node)
              when TypeComparison::NULLABILITY_MISMATCH
                errors << create_error("Nullability mismatch", variable_type, variable_definition, argument_type, argument_node)
              when TypeComparison::NO_ERROR, TypeComparison::INVALID_DEFINITION
                # do nothing
              end
            end
          else
            if !ValidLiteral.valid_literal?(argument_defn.type, argument_node.value)
              parent_type = parent_defn.class.name.split("::").last
              value_string = GraphQL::Language::Generation.generate(argument_node.value)
              errors << AnalysisError.new(
                %|Argument "#{argument_node.name}" on #{parent_type.downcase} "#{parent_defn.name}" has an invalid value, expected type "#{argument_defn.type}" but received #{value_string}|,
                nodes: [argument_node]
              )
            end
          end
          errors
        end

        private

        module_function

        def create_error(error_msg, var_type, var_node, arg_type, arg_node)
          AnalysisError.new(
            %|#{error_msg} on variable "$#{var_node.name}" and argument "#{arg_node.name}" (#{var_type.to_s} / #{arg_type.to_s})|,
            nodes: [var_node, arg_node]
          )
        end

        # Find any definitions for the usage of `var_name` inside `definition_node`:
        # - If it's inside an operation definition, get definitions from that definition
        # - If it's inside a fragment definition, find the operations that use that fragment
        #   and validate the definitions there
        # TODO: this recurses to backtrack over nested fragment dependencies.
        # Can we track that in the dependency map instead of re-doing it here,
        # for _each_ variable?
        # @return [Array<GraphQL::Language::Nodes::FragmentDefinition>] Definitions for `var_name`
        def variable_definitions_for_op_defn(variable_usages, dependencies, definition_node, var_name)
          case definition_node
          when GraphQL::Language::Nodes::OperationDefinition
            variable_usages[definition_node][:defined][var_name]
          when GraphQL::Language::Nodes::FragmentDefinition
            variable_definitions = Set.new
            # TODO: we shouldn't have to ad-hoc backtrack over and over
            dependencies.each_dependency do |dependent_op_defn, frag_defn|
              if frag_defn == definition_node
                variable_definitions.merge(variable_definitions_for_op_defn(variable_usages, dependencies, dependent_op_defn, var_name))
              end
            end
            variable_definitions.to_a
          end
        end
      end
    end
  end
end
