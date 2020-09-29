# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module NodeBehaviors
        def self.included(child_module)
          child_module.extend(DefaultRelay)
          child_module.description("An object with an ID.")
          child_module.field(:id, ID, null: false, description: "ID of the object.")
        end
      end
    end
  end
end
