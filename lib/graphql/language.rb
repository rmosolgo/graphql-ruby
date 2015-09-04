module GraphQL
  module Language
  end
end

require 'graphql/language/parser'
require 'graphql/language/transform'
require 'graphql/language/nodes'
require 'graphql/language/visitor'

module GraphQL
  TRANSFORM = GraphQL::Language::Transform.new
  PARSER = GraphQL::Language::Parser.new
end
