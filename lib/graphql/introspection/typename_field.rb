# frozen_string_literal: true
module GraphQL
  module Introspection
    TypenameField = GraphQL::Field.define do
      name "__typename"
      description "The name of this type"
      type -> { !GraphQL::STRING_TYPE }
      resolve ->(obj, a, ctx) { ctx.irep_node.owner_type }
    end
  end
end
