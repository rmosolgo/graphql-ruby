class GraphQL::Syntax::Field
  attr_reader :identifier, :alias_name, :calls, :fields
  def initialize(identifier:, alias_name: nil, calls: [], fields: [])
    @identifier = identifier
    @alias_name = alias_name
    @calls = calls
    @fields = fields
  end
end