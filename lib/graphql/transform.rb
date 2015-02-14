class GraphQL::Transform < Parslet::Transform
  # query
  rule(nodes: sequence(:n), variables: sequence(:v)) { GraphQL::Syntax::Query.new(nodes: n, variables: v)}
  # node
  rule(identifier: simple(:i), arguments: sequence(:a), fields: sequence(:f)) {GraphQL::Syntax::Node.new(identifier: i.to_s, arguments: a, fields: f)}
  # field
  rule(identifier: simple(:i), calls: sequence(:c), fields: sequence(:f), alias_name: simple(:a)) { GraphQL::Syntax::Field.new(identifier: i.to_s, fields: f, calls: c, alias_name: a.to_s)}
  rule(identifier: simple(:i), calls: sequence(:c), alias_name: simple(:a)) { GraphQL::Syntax::Field.new(identifier: i.to_s, calls: c, alias_name: a.to_s)}
  rule(identifier: simple(:i), calls: sequence(:c), fields: sequence(:f)) { GraphQL::Syntax::Field.new(identifier: i.to_s, fields: f, calls: c)}
  rule(identifier: simple(:i), calls: sequence(:c)) { GraphQL::Syntax::Field.new(identifier: i.to_s, calls: c)}
  rule(identifier: simple(:i), alias_name: simple(:a)) { GraphQL::Syntax::Field.new(identifier: i.to_s, alias_name: a.to_s)}
  # call
  rule(identifier: simple(:i), arguments: sequence(:a)) { GraphQL::Syntax::Call.new(identifier: i.to_s, arguments: a) }
  # argument
  rule(argument: simple(:a)) { a.to_s }
  rule(identifier: simple(:i)) { i.to_s }
  # variable
  rule(identifier: simple(:i), json_string: simple(:j)) { GraphQL::Syntax::Variable.new(identifier: i.to_s, json_string: j.to_s)}
end