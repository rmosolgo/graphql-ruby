# frozen_string_literal: true
require "graphql"

module Dummy
  EdibleInterface = GraphQL::InterfaceType.define do
    name "Edible"
    description "Something you can eat, yum"
    field :fatContent, !types.Float, "Percentage which is fat"
    field :origin, !types.String, "Place the edible comes from"
    field :selfAsEdible, EdibleInterface, resolve: ->(o, a, c) { o }
  end
end
