require 'graphql/language/parser'
require 'graphql/language/transform'
require 'graphql/language/nodes'
require 'graphql/language/visitor'
require 'graphql/language/parse.tab'

module GraphQL
  TRANSFORM = GraphQL::Language::Transform.new
  PARSER = GraphQL::Language::Parser.new
end
