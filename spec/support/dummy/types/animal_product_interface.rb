# -*- coding: utf-8 -*-
# frozen_string_literal: true
require "graphql"

module Dummy
  module Types
    AnimalProductInterface = GraphQL::InterfaceType.define do
      name "AnimalProduct"
      description "Comes from an animal, no joke"
      field :source, !DairyAnimalEnum, "Animal which produced this product"
    end
  end
end
