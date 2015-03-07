# Parser is a [parslet](http://kschiess.github.io/parslet/) parser for parsing queries.
#
# If it failes to parse, a {SyntaxError} is raised.
class GraphQL::Parser < Parslet::Parser
  root(:query)
  rule(:query) { node.repeat.as(:nodes) >> variable.repeat.as(:variables) }
  # node
  rule(:node) { space? >> call >> space? >> fields.as(:fields) }

  # field set
  rule(:fields) { str("{") >> space? >> (field >> separator?).repeat(1) >> space? >> str("}") >> space?}

  #call
  rule(:call) { identifier >> str("(") >> (argument.as(:argument) >> separator?).repeat(0).as(:arguments) >> str(")") }
  rule(:dot) { str(".") }
  rule(:argument) { (identifier | variable_identifier)}

  # field
  rule(:field) { identifier >> call_chain.maybe >> alias_name.maybe >> space? >> fields.as(:fields).maybe }
  rule(:call_chain) { (dot >> call).repeat(0).as(:calls) }
  rule(:alias_name) { space >> str("as") >> space >> name.as(:alias_name) }

  # variable
  rule(:variable) { space? >> variable_identifier >> str(":") >> space? >> (name | json_string ).as(:json_string) >> space?}
  rule(:json_string) { str("{") >> (match('[^{}]') | json_string).repeat >> str("}")}
  rule(:variable_identifier) { (str("<") >> name >> str(">")).as(:identifier) }

  # general purpose
  rule(:separator?) { str(",").maybe >> space? }
  rule(:identifier) { name.as(:identifier) }
  rule(:name) { match('\w').repeat(1) }
  rule(:space) { match('[\s\n]+').repeat(1) }
  rule(:space?) { space.maybe }
end