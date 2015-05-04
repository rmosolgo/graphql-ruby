class GraphQL::UnexpectedReturnsError < GraphQL::Error
  def initialize(call_class, unexpected_returns)
    expected_returns = call_class.return_declarations.keys.join(", ")
    super("#{call_class.name} returned #{unexpected_returns}, but didn't declare them. (It declared #{expected_returns})")
  end
end