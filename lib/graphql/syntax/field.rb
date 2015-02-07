class GraphQL::Syntax::Field
  attr_reader :identifier, :calls, :alias_name
  def initialize(identifier:, alias_name: nil, calls: [])
    @identifier = identifier
    @alias_name = alias_name
    @calls = calls
  end
end