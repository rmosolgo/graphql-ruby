# {Transform} is a [parslet](http://kschiess.github.io/parslet/) transform for for turning the AST into objects in {GraphQL::Syntax}.
class GraphQL::Parser::Transform < Parslet::Transform
  # query
  rule(nodes: sequence(:n), variables: sequence(:v), fragments: sequence(:f)) { GraphQL::Syntax::Query.new(nodes: n, variables: v, fragments: f)}
  # node
  rule(identifier: simple(:i), arguments: sequence(:a), fields: sequence(:f)) {GraphQL::Syntax::Node.new(identifier: i.to_s, arguments: a, fields: f)}
  ### if `fields` is not a sequence, it's `{ }`, an empty array:
  rule(identifier: simple(:i), arguments: sequence(:a), fields: simple(:f)) {GraphQL::Syntax::Node.new(identifier: i.to_s, arguments: a, fields: [])}
  # field
  rule(identifier: simple(:i), calls: sequence(:c), fields: sequence(:f), alias_name: simple(:a), keyword_pairs: sequence(:k)) { GraphQL::Syntax::Field.new(identifier: i.to_s, fields: f, calls: c, alias_name: a, keyword_pairs: k)}
  rule(optional_fields: simple(:f)) { [] }
  rule(optional_fields: sequence(:f)) { f }
  rule(alias_identifier: simple(:a)) { a.to_s}
  # keywords
  rule(keyword: simple(:k), keyword_value: simple(:v)) { GraphQL::Syntax::KeywordPair.new(key: k, value: v)}
  # call
  rule(identifier: simple(:i), arguments: sequence(:a)) { GraphQL::Syntax::Call.new(identifier: i.to_s, arguments: a) }
  # argument
  rule(argument: simple(:a)) { a.to_s }
  rule(identifier: simple(:i)) { i.to_s }
  # variable
  rule(identifier: simple(:i), json_string: simple(:j)) { GraphQL::Syntax::Variable.new(identifier: i.to_s, json_string: j.to_s)}
  # fragment
  rule(identifier: simple(:i), fields: sequence(:f)) { GraphQL::Syntax::Fragment.new(identifier: i, fields: f)}
end