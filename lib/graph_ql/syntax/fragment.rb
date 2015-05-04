class GraphQL::Syntax::Fragment
  attr_reader :identifier, :fields
  def initialize(identifier:, fields:)
    @identifier = identifier
    @fields = fields
  end
end