# frozen_string_literal: true

module Platform
  module Unions
    Account = GraphQL::UnionType.define do
      name "Account"
      description "Users and organizations."
      visibility :internal

      possible_types [
        Objects::User,
        Objects::Organization,
        Objects::Bot
      ]

      resolve_type ->(obj, ctx) { :stand_in }
    end
  end
end
