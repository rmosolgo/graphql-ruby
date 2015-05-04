class GraphQL::Syntax::Variable
  attr_reader :identifier, :json_string
  def initialize(identifier:, json_string:)
    @identifier = identifier
    @json_string = json_string
  end
end