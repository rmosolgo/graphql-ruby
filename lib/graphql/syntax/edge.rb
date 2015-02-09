class GraphQL::Syntax::Edge
  attr_reader :identifier, :fields, :calls
  def initialize(identifier:, fields:, calls:)
    @identifier = identifier
    @calls = calls
    @fields = fields
  end
end