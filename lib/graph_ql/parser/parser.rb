# Parser is a [parslet](http://kschiess.github.io/parslet/) parser for parsing queries.
#
# If it failes to parse, a {SyntaxError} is raised.
class GraphQL::Parser::Parser < Parslet::Parser
  root(:query)
  rule(:query) { node.repeat.as(:nodes) >> variable.repeat.as(:variables) >> fragment.repeat.as(:fragments) }

  # node
  rule(:node) { space? >> call >> space? >> fields.as(:fields) }

  # fragment
  rule(:fragment) { space? >> fragment_identifier >> str(":") >> space? >> fields.as(:fields) >> space?}
  rule(:fragment_identifier) { (str("$") >> name).as(:identifier) }

  # field set
  rule(:fields) { str("{") >> space? >> (field >> separator?).repeat(0) >> space? >> str("}") >> space?}

  # call
  rule(:call) { identifier >> str("(") >> (argument.as(:argument) >> separator?).repeat(0).as(:arguments) >> str(")") }
  rule(:dot) { str(".") }
  rule(:argument) { (identifier | variable_identifier | json_string)}

  # field
  rule(:field) { (identifier | fragment_identifier) >> keyword_arguments >> call_chain.as(:calls).maybe >> alias_name.maybe.as(:alias_name) >> space? >> fields.maybe.as(:optional_fields).as(:fields) }
  rule(:keyword_arguments) { str("(").maybe >> keyword_pair.repeat(0).as(:keyword_pairs).maybe  >> str(")").maybe }
  rule(:keyword_pair) { name.as(:keyword) >> str(":") >> space? >> argument.as(:keyword_value) >> separator? }
  rule(:call_chain) { (dot >> call).repeat(0) }
  rule(:alias_name) { space >> str("as") >> space >> name.as(:alias_identifier) }
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