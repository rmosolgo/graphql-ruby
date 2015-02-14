class GraphQL::Types::CursorField
  def initialize(value)
    @value = value
  end

  def as_result
    @value.to_s
  end
end