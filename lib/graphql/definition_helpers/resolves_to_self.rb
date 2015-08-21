module GraphQL::DefinitionHelpers::ResolvesToSelf
  def resolve_type(object)
    self
  end
end
