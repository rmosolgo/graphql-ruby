class GraphQL::Syntax::Node
  attr_reader :identifier, :arguments, :fields
  def initialize(identifier:, arguments:, fields: [])
    @identifier = identifier
    @arguments = arguments
    @fields = fields
  end
end