# Parser is a [parslet](http://kschiess.github.io/parslet/) parser for parsing queries.
#
# If it failes to parse, a {SyntaxError} is raised.
class GraphQL::Parser::Parser < Parslet::Parser
  root(:document)
  rule(:document) { (space | operation_definition | fragment_definition).repeat(1) }

  # TODO: whitespace sensitive regarding `on`, eg `onFood`, see lookahead note in spec
  rule(:fragment_definition) { str("fragment") >> space? >> name >> space? >> str("on") >> space? >> name >> space? >> directives.maybe >> space? >> selection_set }
  rule(:fragment_spread) { str("...") >> space? >> name >> space? >> directives.maybe }
  rule(:inline_fragment) { str("...") >> space? >> str("on") >> space? >> name >> space? >> directives.maybe >> space? >> selection_set }

  rule(:operation_definition) { (selection_set | named_operation_definition) }
  rule(:named_operation_definition) { operation_type >> space? >> name >> operation_variable_definitions.maybe >> space? >> directives.maybe >> space? >> selection_set}
  rule(:operation_type) { (str("query") | str("mutation")) }
  rule(:operation_variable_definitions) { str("(") >> space? >> (operation_variable_definition >> separator?).repeat(1) >> space? >> str(")") }
  rule(:operation_variable_definition) { value_variable >> space? >> (str("=") >> space? >> value).maybe }

  rule(:selection) { (field | fragment_spread | inline_fragment) >> space? >> separator? }
  rule(:selection_set) { str("{") >> space? >> selection.repeat(1) >> space? >> str("}")}

  rule(:field) { field_alias.maybe >> name >> field_arguments.maybe >> space? >> directives.maybe >> space? >> selection_set.maybe }
  rule(:field_alias) {  name >> space? >> str(":") >> space? }
  rule(:field_arguments) { str("(") >> field_argument.repeat(1) >> str(")") }
  rule(:field_argument) { name >> str(":") >> space? >> value >> separator? }

  rule(:directives) { (directive >> separator?).repeat(1) }
  rule(:directive) { directive_name >> (space? >> str(":") >> space? >> directive_value).maybe }
  rule(:directive_name) { str("@") >> name }
  rule(:directive_value) { value }

  # TODO: Enum
  rule(:value) { (value_float | value_int | value_string | value_boolean | value_array | value_variable | value_input_object) }
  rule(:value_sign?) { str("-").maybe }
  rule(:value_int) { value_sign? >> match('\d').repeat(1) }
  rule(:value_float) { value_sign? >> match('\d').repeat(1) >> str(".") >> match('\d').repeat(1) >> (str("e") >> value_sign? >> match('\d').repeat(1)).maybe }
  # TODO: support unicode, escaped chars (match the spec)
  rule(:value_string) { str('"') >> match('[^\"]').repeat(1) >> str('"')}
  rule(:value_boolean) { str("true") | str("false") }
  rule(:value_array) { str("[") >> (value >> separator?).repeat(0) >> str("]") }
  rule(:value_variable) { str("$") >> name }
  rule(:value_input_object) { str("{") >> (value_input_object_pair  >> separator?).repeat(1) >> str("}") }
  rule(:value_input_object_pair) { space? >> name >>  space? >> str(":") >> space? >> value >> space? }

  rule(:separator?) { (space? >> str(",") >> space?).maybe }
  rule(:identifier) { name.as(:identifier) }
  rule(:name) { match('[_A-Za-z]') >> match('[_0-9A-Za-z]').repeat(0) }
  rule(:space) { (match('[\s\n]+') | comment).repeat(1) }
  rule(:comment) { str("#") >> match('[^\r\n]').repeat(0) }
  rule(:space?) { space.maybe }
end
