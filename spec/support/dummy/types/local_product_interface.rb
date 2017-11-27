# frozen_string_literal: true
require "graphql"

module Dummy
  module Types
    LocalProductInterface = GraphQL::InterfaceType.define do
      name "LocalProduct"
      description "Something that comes from somewhere"
      field :origin, !types.String, "Place the thing comes from"
    end
  end
end
