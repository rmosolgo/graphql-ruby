class GraphQL::StaticValidation::ArgumentsAreDefined
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
    ensure_arguments_defined(node, field_defn.arguments, context)
  end

  def validate_directive(node, context)
    directive_defn = context.schema.directives[node.name]
    ensure_arguments_defined(node, directive_defn.arguments, context)
  end

  def ensure_arguments_defined(node, arguments, context)
    node.arguments.each do |argument|
      argument_defn = arguments[argument.name]
      if argument_defn.nil?
        context.errors << message("#{node.class.name.split("::").last} '#{node.name}' doesn't accept argument #{argument.name}", node)
      end
    end
  end
end
