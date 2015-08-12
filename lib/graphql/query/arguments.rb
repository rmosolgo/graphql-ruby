require 'forwardable'

# Provide read-only access to arguments by string or symbol names.
class GraphQL::Query::Arguments
  extend Forwardable

  def initialize(ast_arguments, argument_hash, variables)
    @hash = ast_arguments.reduce({}) do |memo, arg|
      arg_defn = argument_hash[arg.name]
      value = reduce_value(arg.value, arg_defn, variables)
      memo[arg.name] = value
      memo
    end
  end

  def_delegators :@hash, :keys, :values

  def [](key)
    @hash[key.to_s]
  end

  private

  def reduce_value(value, arg_defn, variables)
    if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
      value = variables[value.name]
    elsif value.is_a?(GraphQL::Language::Nodes::Enum)
      value = arg_defn.type.coerce(value.name)
    elsif value.is_a?(GraphQL::Language::Nodes::InputObject)
      value = self.class.new(value.pairs, arg_defn.type.input_fields, variables)
    else
      value
    end
  end
end
