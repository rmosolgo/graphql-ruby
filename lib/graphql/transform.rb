class GraphQL::Transform < Parslet::Transform
  # node
  rule(identifier: simple(:i), arguments: sequence(:a), fields: sequence(:f)) {GraphQL::Syntax::Node.new(identifier: i.to_s, arguments: a, fields: f)}
  # edge
  rule(identifier: simple(:i), calls: sequence(:c), fields: sequence(:f)) { GraphQL::Syntax::Edge.new(identifier: i.to_s, fields: f, calls: c)}
  # field
  rule(identifier: simple(:i)) { GraphQL::Syntax::Field.new(identifier: i.to_s)}
  rule(identifier: simple(:i), alias_name: simple(:a)) { GraphQL::Syntax::Field.new(identifier: i.to_s, alias_name: a.to_s)}
  # call
  rule(identifier: simple(:i), arguments: sequence(:a)) { GraphQL::Syntax::Call.new(identifier: i.to_s, arguments: a) }
  # argument
  rule(argument: simple(:a)) { a.to_s }
end