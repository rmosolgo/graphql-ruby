module GraphQL
  class Mixin
    include GraphQL::DefinitionHelpers::DefinedByConfig
    defined_by_config :fields
    attr_accessor :fields
  end
end
