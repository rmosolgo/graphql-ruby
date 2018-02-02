# frozen_string_literal: true

module Platform
  module Inputs
    class ReleaseOrder < Platform::Inputs::Base
      description "Ways in which lists of releases can be ordered upon return."

      argument :field, [Enums::ReleaseOrderField], <<-MD, required: false
        The field in which to order releases by.
      MD
      argument :direction, Enums::OrderDirection, "The direction in which to order releases by the specified field.", required: true
    end
  end
end
