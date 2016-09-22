module GraphQL
  module StaticAnalysis
    class TypeCheck
      module ValidSelections
        DYNAMIC_FIELD_PREFIX = "__"
        NO_ERRORS = []

        module_function
        # Assert that the node has selections according to its type.
        # @return [Array<AnalysisError>]errors for this node (maybe an empty array)
        def errors_for_selections(owner_name, parent_type, node)
          field_selections = node.selections.select { |s| s.is_a?(GraphQL::Language::Nodes::Field) }
          user_field_selections = field_selections.select { |s| !s.name.start_with?(DYNAMIC_FIELD_PREFIX) }
          parent_type_kind = parent_type.kind
          error_nodes = NO_ERRORS
          error_message = nil

          if !parent_type_kind.composite? && node.selections.any?
            # It's a scalar with selections
            error_message = "can't have selections"
            error_nodes = node.selections
          elsif !parent_type_kind.fields? && user_field_selections.any?
            # It's a union with direct selections
            error_message = "can't have direct selections, use a fragment spread to access members instead"
            error_nodes = user_field_selections
          elsif !parent_type_kind.scalar? && node.selections.none?
            if parent_type_kind.fields?
              # It's an object or interface with no selections
              error_message = "must have selections"
            else
              # It's a union with no selections
              error_message = "must have selections on a member type"
            end
            error_nodes = [node]
          end

          errors = []

          if error_message
            errors << AnalysisError.new(
              %|Type "#{parent_type.name}" #{error_message}, see #{owner_name}|,
              nodes: error_nodes
            )
          end

          errors
        end
      end
    end
  end
end
