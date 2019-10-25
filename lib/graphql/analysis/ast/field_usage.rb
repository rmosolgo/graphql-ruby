# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      class FieldUsage < Analyzer
        def initialize(query)
          super
          @used_fields = Set.new
          @used_deprecated_fields = Set.new
        end

        def on_leave_field(node, parent, visitor)
          field_defn = visitor.field_definition
          field = "#{visitor.parent_type_definition.graphql_name}.#{field_defn.graphql_name}"
          @used_fields << field
          @used_deprecated_fields << field if field_defn.deprecation_reason
        end

        def result
          {
            used_fields: @used_fields.to_a,
            used_deprecated_fields: @used_deprecated_fields.to_a
          }
        end
      end
    end
  end
end
