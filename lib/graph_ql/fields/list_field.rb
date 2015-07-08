class GraphQL::ListField < GraphQL::AbstractField
  attr_reader :field
  def initialize(field:)
    @field = field
  end

  def type
    GraphQL::LIST_TYPE
  end

  def type;         field.type;         end
  def description;  field.description;  end

  def resolve(object, arguments, context)
    field.resolve(object, arguments, context)
  end
end
