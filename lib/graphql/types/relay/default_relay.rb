# frozen_string_literal: true

module GraphQL
  module Types
    module Relay
      module DefaultRelay
        def self.extended(child_class)
          child_class.default_relay(true)
        end

        def default_relay(new_value)
          @default_relay = new_value
        end

        def default_relay?
          !!@default_relay
        end

        def to_graphql
          type_defn = super
          type_defn.default_relay = default_relay?
          type_defn
        end
      end
    end
  end
end
