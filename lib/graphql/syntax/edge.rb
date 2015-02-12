class GraphQL::Syntax::Edge
  attr_reader :identifier, :fields, :calls, :alias_name
  def initialize(identifier:, fields:, calls:, alias_name: nil)
    @identifier = identifier
    @calls = calls
    @fields = fields
    @alias_name = alias_name
  end
end