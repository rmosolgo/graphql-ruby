# These objects are used to track the schema of the graph
module GraphQL::Schema
  extend ActiveSupport::Autoload
  autoload(:ALL)
  autoload(:Schema)
  autoload(:SchemaValidation)
end
