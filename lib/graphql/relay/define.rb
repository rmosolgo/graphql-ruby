module GraphQL
  module Relay
    module Define
      module AssignConnection
        def self.call(type_defn, *field_args, max_page_size: nil, **field_kwargs, &field_block)
          underlying_field = GraphQL::Define::AssignObjectField.call(type_defn, *field_args, **field_kwargs, &field_block)
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
