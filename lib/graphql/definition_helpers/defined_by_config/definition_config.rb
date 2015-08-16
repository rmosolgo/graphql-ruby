module GraphQL
  module DefinitionHelpers
    module DefinedByConfig
      class DefinitionConfig
        # Wraps a field definition with a ConnectionField
        def connection(name, type = nil, desc = nil, property: nil, &block)
          underlying_field = field(name, type, desc, property: property, &block)
          connection_field = GraphQL::Relay::ConnectionField.create(underlying_field)
          fields[name.to_s] = connection_field
        end
      end
    end
  end
end
