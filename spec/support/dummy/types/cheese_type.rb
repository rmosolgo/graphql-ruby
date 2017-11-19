# -*- coding: utf-8 -*-
# frozen_string_literal: true
require "graphql"

module Dummy
  module Types
    CheeseType = GraphQL::ObjectType.define do
      name "Cheese"
      class_names ["Cheese"]
      description "Cultured dairy product"
      interfaces [Types::EdibleInterface, Types::EdibleAsMilkInterface, Types::AnimalProductInterface, Types::LocalProductInterface]

      # Can have (name, type, desc)
      field :id, !types.Int, "Unique identifier"
      field :flavor, !types.String, "Kind of Cheese"
      field :origin, !types.String, "Place the cheese comes from"

      field :source, !Types::DairyAnimalEnum,
        "Animal which produced the milk for this cheese"

      # Or can define by block, `resolve ->` should override `property:`
      field :similarCheese, CheeseType, "Cheeses like this one", property: :this_should_be_overriden  do
        # metadata test
        joins [:cheeses, :milks]
        argument :source, !types[!Types::DairyAnimalEnum]
        argument :nullableSource, types[!Types::DairyAnimalEnum], default_value: [1]
        resolve ->(t, a, c) {
          # get the strings out:
          sources = a["source"]
          if sources.include?("YAK")
            raise NoSuchDairyError.new("No cheeses are made from Yak milk!")
          else
            CHEESES.values.find { |cheese| sources.include?(cheese.source) }
          end
        }
      end

      field :nullableCheese, CheeseType, "Cheeses like this one" do
        argument :source, types[!Types::DairyAnimalEnum]
        resolve ->(t, a, c) { raise("NotImplemented") }
      end

      field :deeplyNullableCheese, CheeseType, "Cheeses like this one" do
        argument :source, types[types[Types::DairyAnimalEnum]]
        resolve ->(t, a, c) { raise("NotImplemented") }
      end

      # Keywords can be used for definition methods
      field :fatContent,
        property: :fat_content,
        type: !GraphQL::FLOAT_TYPE,
        description: "Percentage which is milkfat",
        deprecation_reason: "Diet fashion has changed"
    end
  end
end
