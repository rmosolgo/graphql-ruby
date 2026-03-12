# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module NodeBehaviors
        def self.included(child_module)
          child_module.extend(ClassMethods)
          child_module.extend(ExecutionMethods)
          child_module.description("An object with an ID.")
          child_module.field(:id, ID, null: false, description: "ID of the object.", resolver_method: :default_global_id, resolve_each: :default_global_id)
        end

        def default_global_id
          self.class.default_global_id(object, context)
        end

        module ClassMethods
          def default_relay?
            true
          end
        end

        module ExecutionMethods
          def default_global_id(object, context)
            context.schema.id_from_object(object, self, context)
          end

          def included(child_class)
            child_class.extend(ExecutionMethods)
          end
        end
      end
    end
  end
end
