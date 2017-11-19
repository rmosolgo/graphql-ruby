# -*- coding: utf-8 -*-
# frozen_string_literal: true
require "graphql"

module Dummy
  module Types
    BeverageUnion = GraphQL::UnionType.define do
      name "Beverage"
      description "Something you can drink"
      possible_types [MilkType]
    end
  end
end
