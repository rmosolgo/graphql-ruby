# frozen_string_literal: true

module Platform
  module Inputs
    ReleaseOrder = GraphQL::InputObjectType.define do
      name "ReleaseOrder"
      description "Ways in which lists of releases can be ordered upon return."

      input_field :field, types[!Enums::ReleaseOrderField], <<-MD
        The field in which to order releases by.
      MD
      input_field :direction, !Enums::OrderDirection, "The direction in which to order releases by the specified field."
    end
  end
end
