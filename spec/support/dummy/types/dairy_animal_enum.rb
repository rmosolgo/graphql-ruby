# frozen_string_literal: true
require "graphql"

module Dummy
  module Types
    DairyAnimalEnum = GraphQL::EnumType.define do
      name "DairyAnimal"
      description "An animal which can yield milk"
      value("COW",      "Animal with black and white spots", value: 1)
      value("DONKEY",   "Animal with fur", value: :donkey)
      value("GOAT",     "Animal with horns")
      value("REINDEER", "Animal with horns", value: 'reindeer')
      value("SHEEP",    "Animal with wool")
      value("YAK",      "Animal with long hair", deprecation_reason: "Out of fashion")
    end
  end
end
