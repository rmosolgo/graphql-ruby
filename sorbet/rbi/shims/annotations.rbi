# typed: true

# Corrections to signatures in sorbet/rbi/annotations/graphql.rbi
module GraphQL::Schema::Member::BaseDSLMethods
  # This is also called without an argument to read the description
  sig { params(new_description: T.nilable(String)).returns(T.nilable(String)) }
  def description(new_description = T.unsafe(nil)); end
end
