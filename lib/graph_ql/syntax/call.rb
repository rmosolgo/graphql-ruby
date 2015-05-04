class GraphQL::Syntax::Call
  attr_reader :identifier, :arguments, :calls
  def initialize(identifier:, arguments: nil, calls: [])
    @identifier = identifier
    @arguments = arguments
    @calls = calls
  end
end