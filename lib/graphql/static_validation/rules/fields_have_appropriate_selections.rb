module GraphQL
  module StaticValidation
    # Scalars _can't_ have selections
    # Objects _must_ have selections
    class FieldsHaveAppropriateSelections
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::Field] << ->(node, parent)  {
          return if context.skip_field?(node.name)
          field_defn = context.field_definition
          validate_field_selections(node, field_defn, context)
        }
      end

      private

      def validate_field_selections(ast_field, field_defn, context)
        resolved_type = field_defn.type.unwrap

        if resolved_type.kind.scalar? && ast_field.selections.any?
          error = message("Selections can't be made on scalars (field '#{ast_field.name}' returns #{resolved_type.name} but has selections [#{ast_field.selections.map(&:name).join(", ")}])", ast_field, context: context)
        elsif resolved_type.kind.object? && ast_field.selections.none?
          error = message("Objects must have selections (field '#{ast_field.name}' returns #{resolved_type.name} but has no selections)", ast_field, context: context)
        else
          error = nil
        end

        if !error.nil?
          context.errors << error
          GraphQL::Language::Visitor::SKIP
        end
      end
    end
  end
end
