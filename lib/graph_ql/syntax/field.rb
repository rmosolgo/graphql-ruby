class GraphQL::Syntax::Field
  attr_reader :identifier, :alias_name, :calls, :fields, :keyword_pairs
  def initialize(identifier:, alias_name: nil, keyword_pairs: [],calls: [], fields: [])
    @identifier = identifier
    @alias_name = alias_name
    @calls = calls
    @fields = fields
    @keyword_pairs = keyword_pairs
  end
end