# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class NoDefinitionsArePresent
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        schema_definition_nodes = []
        register_node = ->(node, _p) {
          schema_definition_nodes << node
          GraphQL::Language::Visitor::SKIP
        }

        visitor = context.visitor

        visitor[GraphQL::Language::Nodes::DirectiveDefinition] << register_node
        visitor[GraphQL::Language::Nodes::SchemaDefinition] << register_node
        visitor[GraphQL::Language::Nodes::ScalarTypeDefinition] << register_node
        visitor[GraphQL::Language::Nodes::ObjectTypeDefinition] << register_node
        visitor[GraphQL::Language::Nodes::InputObjectTypeDefinition] << register_node
        visitor[GraphQL::Language::Nodes::InterfaceTypeDefinition] << register_node
        visitor[GraphQL::Language::Nodes::UnionTypeDefinition] << register_node
        visitor[GraphQL::Language::Nodes::EnumTypeDefinition] << register_node

        visitor[GraphQL::Language::Nodes::SchemaExtension] << register_node
        visitor[GraphQL::Language::Nodes::ScalarTypeExtension] << register_node
        visitor[GraphQL::Language::Nodes::ObjectTypeExtension] << register_node
        visitor[GraphQL::Language::Nodes::InputObjectTypeExtension] << register_node
        visitor[GraphQL::Language::Nodes::InterfaceTypeExtension] << register_node
        visitor[GraphQL::Language::Nodes::UnionTypeExtension] << register_node
        visitor[GraphQL::Language::Nodes::EnumTypeExtension] << register_node

        visitor[GraphQL::Language::Nodes::Document].leave << ->(node, _p) {
          if schema_definition_nodes.any?
            context.errors << message(%|Query cannot contain schema definitions|, schema_definition_nodes, context: context)
          end
        }
      end
    end
  end
end
