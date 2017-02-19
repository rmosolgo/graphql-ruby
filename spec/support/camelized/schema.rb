# frozen_string_literal: true
module Camelized
  Shop = GraphQL::ObjectType.define do
    name "Shop"
    field :shop_name, types.String
    field :a_field_with_arguments, types.String do
      argument :an_argument, !types.String
      resolve ->(shop, args, _) {
        require 'byebug'; byebug
        args['an_argument']
      }
    end
  end

  MutationType = GraphQL::ObjectType.define do
    name "Mutation"
    description "The root for mutations in this schema"
    field :add_product, !types.String do
      argument :product_name, !types.String

      resolve ->(o, args, ctx) {
        args[:product_name]
      }
    end
  end

  QueryType = GraphQL::ObjectType.define do
    name "Query"
    field :shop, Camelized::Shop, resolve: ->(_, _, _) { Camelized::ShopObject }
  end

  Schema = GraphQL::Schema.define do
    camelize(true)

    query(QueryType)
    mutation(MutationType)
  end
end
