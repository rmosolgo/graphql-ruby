class GraphQL::Parser < Parslet::Parser
  root(:node)

  # node
  rule(:node) { space? >> call >> space? >> fields.as(:fields) }

  # field set
  rule(:fields) { str("{") >> space? >> ((edge | field) >> separator?).repeat(1) >> space? >> str("}") >> space?}

  # edge
  rule(:edge) { field >> space? >> fields.as(:fields) }

  #call
  rule(:call) { identifier >> str("(") >> (name.as(:argument) >> separator?).repeat(0).as(:arguments) >> str(")") }
  rule(:dot) { str(".") }

  # field
  rule(:field) { identifier >> call_chain.maybe >> alias_name.maybe }
  rule(:call_chain) { (dot >> call).repeat(0).as(:calls) }
  rule(:alias_name) { space >> str("as") >> space >> name.as(:alias_name) }

  # general purpose
  rule(:separator?) { str(",").maybe >> space? }
  rule(:identifier) { name.as(:identifier) }
  rule(:name) { match('\w').repeat(1) }
  rule(:space) { match('[\s\n]+').repeat(1) }
  rule(:space?) { space.maybe }
end