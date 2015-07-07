class GraphQL::ScalarType < GraphQL::Type
  def coerce(value)
    raise NotImplementedError
  end
end
