# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Scalars _can't_ have selections
    # Objects _must_ have selections
    class FieldsHaveAppropriateSelections
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        context.visitor[GraphQL::Language::Nodes::Field] << ->(node, parent)  {
          field_defn = context.field_definition
          validate_field_selections(node, field_defn.type.unwrap, context)
        }

        context.visitor[GraphQL::Language::Nodes::OperationDefinition] << ->(node, parent)  {
          validate_field_selections(node, context.type_definition, context)
        }
      end

      private


      def validate_field_selections(ast_node, resolved_type, context)
        msg = if resolved_type.nil?
          nil
        elsif resolved_type.kind.scalar? && ast_node.selections.any?
          if ast_node.selections.first.is_a?(GraphQL::Language::Nodes::InlineFragment)
            "Selections can't be made on scalars (%{node_name} returns #{resolved_type.name} but has inline fragments [#{ast_node.selections.map(&:type).map(&:name).join(", ")}])"
          else
            "Selections can't be made on scalars (%{node_name} returns #{resolved_type.name} but has selections [#{ast_node.selections.map(&:name).join(", ")}])"
          end
        elsif resolved_type.kind.fields? && ast_node.selections.none?
          "Field must have selections (%{node_name} returns #{resolved_type.name} but has no selections. Did you mean '#{ast_node.name} { ... }'?)"
        else
          nil
        end

        if msg
          node_name = case ast_node
          when GraphQL::Language::Nodes::Field
            "field '#{ast_node.name}'"
          when GraphQL::Language::Nodes::OperationDefinition
            if ast_node.name.nil?
              "anonymous query"
            else
              "#{ast_node.operation_type} '#{ast_node.name}'"
            end
          else
            raise("Unexpected node #{ast_node}")
          end
          context.errors << message(msg % { node_name: node_name }, ast_node, context: context)
          GraphQL::Language::Visitor::SKIP
        end
      end
    end
  end
end
