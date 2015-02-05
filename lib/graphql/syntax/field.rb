class GraphQL::Syntax::Field
  attr_reader :identifier, :calls
  def initialize(identifier:, calls: [])
    @identifier = identifier
    @calls = calls
  end
end