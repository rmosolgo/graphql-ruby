class GraphQL::Syntax::Node
  attr_reader :identifier, :argument, :fields
  def initialize(identifier:, argument:, fields: [])
    @identifier = identifier
    @argument = argument
    @fields = fields
  end

  def execute!(query)
    obj = identifier.execute!(query)
    fields.each do |field|
      obj.apply_field(field)
    end
  end
end