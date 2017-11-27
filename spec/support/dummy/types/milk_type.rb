# frozen_string_literal: true
require "graphql"

module Dummy
  module Types
    MilkType = GraphQL::ObjectType.define do
      name "Milk"
      description "Dairy beverage"
      interfaces [Types::EdibleInterface, Types::EdibleAsMilkInterface, Types::AnimalProductInterface, Types::LocalProductInterface]
      field :id, !types.ID
      field :source, !Types::DairyAnimalEnum, "Animal which produced this milk", hash_key: :source
      field :origin, !types.String, "Place the milk comes from"
      field :flavors, types[types.String], "Chocolate, Strawberry, etc" do
        argument :limit, types.Int
        resolve ->(milk, args, ctx) {
          args[:limit] ? milk.flavors.first(args.limit) : milk.flavors
        }
      end
      field :executionError do
        type GraphQL::STRING_TYPE
        resolve ->(t, a, c) { raise(GraphQL::ExecutionError, "There was an execution error") }
      end

      field :allDairy, -> { types[DairyProductUnion] } do
        resolve ->(obj, args, ctx) { CHEESES.values + MILKS.values }
      end
    end
  end
end

