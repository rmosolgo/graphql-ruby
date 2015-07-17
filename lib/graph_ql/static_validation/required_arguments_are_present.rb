class GraphQL::StaticValidation::RequiredArgumentsArePresent
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    visitor = context.visitor
    visitor[GraphQL::Nodes::Field] << -> (node, parent) {
      validate_field(node, context)
    }
    visitor[GraphQL::Nodes::Directive] << -> (node, parent) {
      validate_directive(node, context)
    }
  end

  private

  def validate_field(node, context)
    field_defn = context.field_definition
    ensure_no_missing(node, field_defn.arguments, context)
  end

  def validate_directive(node, context)
    directive_defn = context.schema.directives[node.name]
    ensure_no_missing(node, directive_defn.arguments, context)
  end


  def ensure_no_missing(node, argument_defns, context)
    present_argument_names = node.arguments.map(&:name)
    required_argument_names = argument_defns.values
      .select { |a| a.type.kind.non_null? }
      .map(&:name)

    missing_names = required_argument_names - present_argument_names
    if missing_names.any?
      context.errors << message("#{node.class.name.split("::").last} '#{node.name}' is missing required arguments: #{missing_names.join(", ")}", node)
    end
  end
end
