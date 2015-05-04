# These objects are skinny wrappers for going from the AST to actual {Node} and {Field} instances.
module GraphQL::Syntax
  extend ActiveSupport::Autoload
  autoload(:Call)
  autoload(:Field)
  autoload(:Query)
  autoload(:Fragment)
  autoload(:Node)
  autoload(:Variable)
end