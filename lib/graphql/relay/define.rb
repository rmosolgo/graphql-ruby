module GraphQL
  module Relay
    module Define
      module AssignConnection
        def self.call(type_defn, name, type = nil, desc = nil, property: nil, max_page_size: nil, &block)
          underlying_field = GraphQL::Define::AssignObjectField.call(type_defn, name, type, desc, property: property, &block)
          connection_field = GraphQL::Relay::ConnectionField.create(underlying_field, max_page_size: max_page_size)
          type_defn.fields[name.to_s] = connection_field
        end
      end

      module AssignGlobalIdField
        def self.call(type_defn, field_name)
          type_defn.name || raise("You must define the type's name before creating a GlobalIdField")
          GraphQL::Define::AssignObjectField.call(type_defn, field_name, field: GraphQL::Relay::GlobalIdField.new(type_defn.name))
        end
      end
    end
  end
end
