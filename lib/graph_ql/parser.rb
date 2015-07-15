require 'graph_ql/parser/nodes'
require 'graph_ql/parser/parser'
require 'graph_ql/parser/transform'
require 'graph_ql/parser/visitor'

module GraphQL
  PARSER = GraphQL::Parser.new
  TRANSFORM = GraphQL::Transform.new
end
