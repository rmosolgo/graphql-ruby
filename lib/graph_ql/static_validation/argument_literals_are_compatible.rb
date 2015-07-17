# - scalars
# - input objects
# - lists
class GraphQL::StaticValidation::ArgumentLiteralsAreCompatible
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
    validate_arguments_match(node, field_defn, context)
  end

  def validate_directive(node, context)
    directive_defn = context.schema.directives[node.name]
    validate_arguments_match(node, directive_defn, context)
  end

  def validate_arguments_match(node, defn, context)
    args_with_literals = node.arguments.select {|a| !a.value.is_a?(GraphQL::Nodes::VariableIdentifier)}
    validator = GraphQL::StaticValidation::LiteralValidator.new
    args_with_literals.each do |arg|
      arg_defn = defn.arguments[arg.name]
      valid = validator.validate(arg.value, arg_defn.type)
      if !valid
        context.errors << message("#{arg.name} on #{node.class.name.split("::").last} '#{node.name}' has an invalid value", node)
      end
    end
  end
end
