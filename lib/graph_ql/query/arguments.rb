# Creates a plain hash out of arguments, looking up variables if necessary
class GraphQL::Query::Arguments
  attr_reader :to_h
  def initialize(ast_arguments, argument_hash, variables)
    @to_h = ast_arguments.reduce({}) do |memo, arg|
      arg_defn = argument_hash[arg.name]
      value = reduce_value(arg.value, arg_defn, variables)
      memo[arg.name] = value
      memo
    end
  end

  private

  def reduce_value(value, arg_defn, variables)
    if value.is_a?(GraphQL::Nodes::VariableIdentifier)
      value = variables[value.name]
    elsif value.is_a?(GraphQL::Nodes::Enum)
      value = arg_defn.type.coerce(value.name)
    elsif value.is_a?(GraphQL::Nodes::InputObject)
      value = self.class.new(value.pairs, arg_defn.type.input_fields, variables).to_h
    else
      value
    end
  end
end
