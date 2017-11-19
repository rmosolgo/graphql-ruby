# frozen_string_literal: true
require "graphql"
require_relative "./edible_interface"

module Dummy
  module Types
    EdibleAsMilkInterface = Types::EdibleInterface.redefine do
      name "EdibleAsMilk"
      description "Milk :+1:"
      resolve_type ->(obj, ctx) { MilkType }
    end
  end
end
