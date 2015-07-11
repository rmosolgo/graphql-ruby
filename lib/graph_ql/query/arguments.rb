# Creates a plain hash out of arguments, looking up variables if necessary
class GraphQL::Query::Arguments
  attr_reader :to_h
  def initialize(ast_arguments, variables)
    @to_h = ast_arguments.reduce({}) do |memo, arg|
      value = reduce_value(arg.value, variables)
      memo[arg.name] = value
      memo
    end
  end

  private

  def reduce_value(value, variables)
    if value.is_a?(GraphQL::Nodes::VariableIdentifier)
      value = variables[value.name]
    elsif value.is_a?(GraphQL::Nodes::Enum)
      value = value.name
    elsif value.is_a?(GraphQL::Nodes::InputObject)
      value = self.class.new(value.pairs, variables).to_h
    else
      value
    end
  end
end
