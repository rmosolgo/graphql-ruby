# Provide read-only access to arguments by string or symbol names.
class GraphQL::Query::Arguments
  extend Forwardable

  def initialize(ast_arguments, argument_hash, variables)
    @hash = ast_arguments.reduce({}) do |memo, arg|
      arg_defn = argument_hash[arg.name]
      value = reduce_value(arg.value, arg_defn.type, variables)
      memo[arg.name] = value
      memo
    end
  end

  def_delegators :@hash, :keys, :values, :inspect, :to_h, :key?, :has_key?

  # Find an argument by name.
  # (Coerce to strings because we use strings internally.)
  # @param [String, Symbol] Argument name to access
  def [](key)
    @hash[key.to_s]
  end

  private

  def reduce_value(value, arg_type, variables)
    if value.is_a?(GraphQL::Language::Nodes::VariableIdentifier)
      raw_value = variables[value.name]
      reduce_value(raw_value, arg_type, variables)
    elsif value.is_a?(GraphQL::Language::Nodes::Enum)
      value = arg_type.coerce_input!(value.name)
    elsif value.is_a?(GraphQL::Language::Nodes::InputObject)
      wrapped_type = arg_type.unwrap
      value = self.class.new(value.pairs, wrapped_type.input_fields, variables)
    elsif arg_type.kind.list?
      value.map { |item| reduce_value(item, arg_type.of_type, variables) }
    elsif arg_type.kind.non_null?
      reduce_value(value, arg_type.of_type, variables)
    elsif arg_type.kind.scalar?
      arg_type.coerce_input!(value)
    else
      raise "Unknown input #{value} of type #{arg_type}"
    end
  end
end
