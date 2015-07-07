class GraphQL::NonNullField
  attr_reader :field
  def initialize(field:)
    @field = field
  end

  def type;         field.type;         end
  def description;  field.description;  end

  def resolve(object, arguments, context)
    field.resolve(object, arguments, context)
  end
end
