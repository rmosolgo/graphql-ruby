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
        # @param schema [GraphQL::Schema] the schema for this query
        # @param prev_type [GraphQL::BaseType] the "outer" type, receiving a spread
        # @param next_type [GraphQL::BaseType] the "inner" type, attempting to be spread inside `prev_type`
        # @param next_node [GraphQL::Language::Nodes::AbstractNode] The AST node which is trying to apply `next_type` inside `prev_type`
        # @param owner_name [String] the name of this node, for use in any error messages
        # @return [Array<GraphQL::StaticAnalysis::AnalysisError>] Any errors for this spread (may be empty)
        def errors_for_spread(schema, prev_type, next_type, next_node, owner_name)
          errors = []
          # Check the common case first
          if (prev_type == next_type) || (prev_type == AnyType) || (next_type == AnyType)
            errors
          else

            prev_inner_type = prev_type.unwrap
            # next_type is already unwrapped
            prev_possible_types = schema.possible_types(prev_inner_type)
            next_possible_types = schema.possible_types(next_type)
            overlapping_possible_types = prev_possible_types & next_possible_types

            if overlapping_possible_types.none?
              reason = mismatch_reason(prev_inner_type, next_type)
              errors << AnalysisError.new(
                "Can't spread #{next_type.name} inside #{prev_inner_type.name} (#{reason}), #{owner_name} is invalid",
                nodes: [next_node]
              )
            end

            errors
          end
        end

        private

        module_function

        def mismatch_reason(prev_type, next_type)
          case prev_type.kind
          when GraphQL::TypeKinds::OBJECT
            case next_type.kind
            when GraphQL::TypeKinds::OBJECT
              "object types must match"
            when GraphQL::TypeKinds::INTERFACE

            end
          when GraphQL::TypeKinds::INTERFACE
            case next_type.kind
            when GraphQL::TypeKinds::OBJECT
              "#{next_type} doesn't implement #{prev_type}"
            end
          when GraphQL::TypeKinds::UNION
            case next_type.kind
            when GraphQL::TypeKinds::OBJECT
              "#{next_type} is not a member of #{prev_type}"
            when GraphQL::TypeKinds::INTERFACE

            end
          end
        end
      end
    end
  end
end
