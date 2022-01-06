# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module NodeBehaviors
        def self.included(child_module)
          child_module.extend(DefaultRelay)
          child_module.description("An object with an ID.")
          child_module.field(:id, ID, null: false, description: "ID of the object.", resolver_method: :default_global_id)
        end

        def default_global_id
          context.schema.id_from_object(object, self, context)
        end
      end
    end
  end
end
