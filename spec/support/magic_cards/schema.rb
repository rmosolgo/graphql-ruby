# frozen_string_literal: true
module MagicCards
  Schema = GraphQL::Schema.from_definition("./spec/support/magic_cards/schema.graphql")

  ResolveType = ->(obj, ctx) {
    raise "Not Implemented"
  }
end
