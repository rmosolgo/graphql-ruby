# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    #--
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
    # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor::ContextMethods
    module FieldsAreDefinedOnType
      #: (GraphQL::Language::Nodes::Field node, GraphQL::Language::Nodes::AbstractNode parent) -> void
      def on_field(node, parent)
        # Fields are only visited inside a known type (other rules stop the visit otherwise)
        parent_type = parent_type_definition #: as !nil
        field = context.types.field(parent_type, node.name)

        if field.nil?
          if parent_type.kind.union?
            add_error(GraphQL::StaticValidation::FieldsHaveAppropriateSelectionsError.new(
              "Selections can't be made directly on unions (see selections on #{parent_type.graphql_name})",
              nodes: parent,
              node_name: parent_type.graphql_name
            ))
          else
            suggestion = if schema.did_you_mean
              context.did_you_mean_suggestion(node.name, possible_fields(context, parent_type))
            end
            message = "Field '#{node.name}' doesn't exist on type '#{parent_type.graphql_name}'#{suggestion}"
            add_error(GraphQL::StaticValidation::FieldsAreDefinedOnTypeError.new(
              message,
              nodes: node,
              field: node.name,
              type: parent_type.graphql_name
            ))
          end
        else
          super
        end
      end

      private

      #: (GraphQL::StaticValidation::ValidationContext context, GraphQL::Schema::Member::type_definition parent_type) -> Array[String]
      def possible_fields(context, parent_type)
        return EmptyObjects::EMPTY_ARRAY if parent_type.kind.leaf?
        context.types.fields(parent_type).map(&:graphql_name)
      end
    end
  end
end
