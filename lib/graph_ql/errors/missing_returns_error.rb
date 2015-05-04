class GraphQL::MissingReturnsError < GraphQL::Error
  def initialize(call_class, missing_returns)
    super("#{self.class.name} declared #{missing_returns}, but didn't return them.")
  end
end
