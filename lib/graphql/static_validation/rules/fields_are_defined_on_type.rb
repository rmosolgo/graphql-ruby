module GraphQL
  module StaticValidation
    class FieldsAreDefinedOnType
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        visitor = context.visitor
        visitor[GraphQL::Language::Nodes::Field] << ->(node, parent) {
          return if context.skip_field?(node.name)
          parent_type = context.object_types[-2]
          parent_type = parent_type.unwrap
          validate_field(context, node, parent_type, parent)
        }
      end

      private

      def validate_field(context, ast_field, parent_type, parent)
        if parent_type.kind.union?
          context.errors << message("Selections can't be made directly on unions (see selections on #{parent_type.name})", parent, context: context)
          return GraphQL::Language::Visitor::SKIP
        end

        field = context.schema.get_field(parent_type, ast_field.name)
        if field.nil?
          context.errors << message("Field '#{ast_field.name}' doesn't exist on type '#{parent_type.name}'", ast_field, context: context)
          return GraphQL::Language::Visitor::SKIP
        end
      end
    end
  end
end
