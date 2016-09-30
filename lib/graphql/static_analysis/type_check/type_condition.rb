module GraphQL
  module StaticAnalysis
    class TypeCheck
      module TypeCondition
        module_function
        # Validate the type condition on `node`
        def errors_for_type_condition(node, next_type, owner_name)
          errors = []
          if next_type.nil?
            errors << AnalysisError.new(
              %|Type "#{node.type}" doesn't exist, so it can't be used as a fragment type|,
              nodes: [node]
            )
          else
            errors.concat(ValidSelections.errors_for_selections(owner_name, next_type, node))
          end
          errors
        end

        # Check for errors when spreading from `prev_type` into `next_type`
        # @param prev_type [GraphQL::BaseType] the "outer" type, receiving a spread
        # @param next_type [GraphQL::BaseType] the "inner" type, attempting to be spread inside `prev_type`
        # @param next_node [GraphQL::Language::Nodes::AbstractNode] The AST node which is trying to apply `next_type` inside `prev_type`
        # @param owner_name [String] the name of this node, for use in any error messages
        # @return [Array<GraphQL::StaticAnalysis::AnalysisError>] Any errors for this spread (may be empty)
        def errors_for_spread(prev_type, next_type, next_node)
          errors = []
          case prev_type.kind
          when GraphQL::TypeKinds::OBJECT
          when GraphQL::TypeKinds::UNION
          when GraphQL::TypeKinds::INTERFACE
          else
            # There's some kind of upstream error,
            # don't worry about it
          end
          errors
        end
      end
    end
  end
end
