# These objects are singletons used to parse queries
module GraphQL::Parser
  extend ActiveSupport::Autoload
  autoload(:Parser)
  autoload(:Transform)
end