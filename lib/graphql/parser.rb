class GraphQL::Parser < Parslet::Parser
  root(:node)

  rule(:node) { space? >> call >> space? >> fields.as(:fields) }

  rule(:fields) { str("{") >> space? >> ((edge | field) >> separator?).repeat(1) >> space? >> str("}") >> space?}

  rule(:edge) { call_chain >> space? >> fields.as(:fields) }
  rule(:call_chain) { identifier >> (dot >> call).repeat(0).as(:calls) }

  rule(:call) { identifier >> str("(") >> (name.as(:argument) >> separator?).repeat(0).as(:arguments) >> str(")") }
  rule(:dot) { str(".") }

  rule(:field) { identifier }

  rule(:separator?) { str(",").maybe >> space? }
  rule(:identifier) { name.as(:identifier) }
  rule(:name) { match('\w').repeat(1) }
  rule(:space) { match('[\s\n]+').repeat(1) }
  rule(:space?) { space.maybe }
end