class GraphQL::Fields::CursorField
  def initialize(value)
    @value = value
  end

  def as_result
    @value.to_s
  end
end