class GraphQL::StaticValidation::FieldsAreDefinedOnType
  include GraphQL::StaticValidation::Message::MessageHelper

  IS_FIELD = Proc.new {|f| f.is_a?(GraphQL::Language::Nodes::Field) }

  def validate(context)
    visitor = context.visitor
    visitor[GraphQL::Language::Nodes::Field] << -> (node, parent) {
      return if context.skip_field?(node.name)
      parent_type = context.object_types[-2]
      parent_type = parent_type.unwrap
      validate_field(context.errors, node, parent_type, parent)
    }
  end

  private

  def validate_field(errors, ast_field, parent_type, parent)
    if parent_type.kind.union?
      errors << message("Selections can't be made directly on unions (see selections on #{parent_type.name})", parent)
      return GraphQL::Language::Visitor::SKIP
    end

    field =  parent_type.fields[ast_field.name]
    if field.nil?
      errors << message("Field '#{ast_field.name}' doesn't exist on type '#{parent_type.name}'", parent)
      return GraphQL::Language::Visitor::SKIP
    end
  end
end
