module GraphQL
  module StaticAnalysis
    class TypeCheck
      module ValidArguments
        module_function
        # @return [Array<AnalysisError>] Any errors found for this argument
        def errors_for_argument(root_node, variable_usages, parent_defn, argument_defn, argument_node)
          errors = []
          case argument_node.value
          when GraphQL::Language::Nodes::VariableIdentifier
          else
            if !valid_literal?(argument_defn.type, argument_node.value)
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
        # @param [GraphQL::BaseType] The type of the argument to check
        # @param [Any] The value parse from the document
        # @return [Boolean] Is `literal_value` a valid input for `type`
        def valid_literal?(type, literal_value)
          if type == AnyInput
            true
          elsif type.kind.non_null?
            (!literal_value.nil?) && valid_literal?(type.of_type, literal_value)
          elsif type.kind.list?
            item_type = type.of_type
            array_value = literal_value.is_a?(Array) ? literal_value : [literal_value]
            array_value.all? { |item| valid_literal?(item_type, item) }
          elsif type.kind.scalar? && !literal_value.is_a?(GraphQL::Language::Nodes::AbstractNode) && !literal_value.is_a?(Array)
            type.valid_input?(literal_value)
          elsif type.kind.enum? && literal_value.is_a?(GraphQL::Language::Nodes::Enum)
            type.valid_input?(literal_value.name)
          elsif type.kind.input_object? && literal_value.is_a?(GraphQL::Language::Nodes::InputObject)
            literal_value.arguments.all? do |inner_ast_node|
              inner_argument_defn = type.get_argument(inner_ast_node.name)
              valid_literal?(inner_argument_defn.type, inner_ast_node.value)
            end
          else
            false
          end
        end
      end
    end
  end
end
