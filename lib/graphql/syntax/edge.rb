class GraphQL::Syntax::Edge
  attr_reader :identifier, :fields, :calls
  def initialize(identifier:, fields:, calls:)
    @identifier = identifier
    @calls = calls
    @fields = fields
  end

  def call_hash
    calls.inject({}) { |memo, call| memo[call.identifier] = call.argument; memo }
  end
end