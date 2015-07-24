module GraphQL::NonNullWithBang
  def !
    GraphQL::NonNullType.new(of_type: self)
  end
end
