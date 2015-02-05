class GraphQL::Syntax::Call
  attr_reader :identifier, :argument, :calls
  def initialize(identifier:, argument: nil, calls: [])
    @identifier = identifier
    @argument = argument
    @calls = calls
  end

  def execute!(query)
    node_class = query.get_node(identifier)
    node_class.call(argument)
  end

  def to_query
    (["#{identifier}(#{argument})"] + calls.map(&:to_query)).join(".")
  end
end