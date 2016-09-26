module GraphQL
  module StaticAnalysis
    class TypeCheck
      module ValidVariables
        module_function

        # @return [Array<AnalysisError>] Any analysis errors from this variable's definition
        def definition_errors(variable_name, defn_node, schema)
          errors = []
          type_name = defn_node.type.unwrap.name
          type_defn = schema.types.fetch(type_name, nil)
          if type_defn.nil?
            errors << AnalysisError.new(
              %|Unknown type "#{type_name}" can't be used for variable "$#{variable_name}"|,
              nodes: [defn_node]
            )
          elsif !type_defn.kind.input?
            errors << AnalysisError.new(
              %|Type "#{type_name}" for "$#{variable_name}" isn't a valid input (must be INPUT_OBJECT, SCALAR, or ENUM, not #{type_defn.kind.name})|,
              nodes: [defn_node]
            )
          elsif !defn_node.default_value.nil?
            if defn_node.type.is_a?(GraphQL::Language::Nodes::NonNullType)
              errors << AnalysisError.new(
                %|Non-null variable "$#{variable_name}" can't have a default value|,
                nodes: [defn_node]
              )
            else
              # If the type wasn't defined, we would have discovered it above
              type = schema.type_from_ast(defn_node.type)
              if !ValidLiteral.valid_literal?(type, defn_node.default_value)
                value_string = GraphQL::Language::Generation.generate(defn_node.default_value)
                errors << AnalysisError.new(
                  %|Variable "$#{variable_name}" default value #{value_string} doesn't match type #{type}|,
                  nodes: [defn_node]
                )
              end
            end
          end
          errors
        end
      end
    end
  end
end
