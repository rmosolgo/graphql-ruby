# Some conveniences for definining arguments.
#
# Passed into initialization blocks, eg {InputObjectType#initialize}, {Field#initialize}
class GraphQL::ArgumentDefiner
  include Singleton

  def build(type:, desc: "", default_value: nil)
    GraphQL::InputValue.new(type: type, description: desc, default_value: default_value)
  end
end
