# Parser is a [parslet](http://kschiess.github.io/parslet/) parser for parsing queries.
#
# If it failes to parse, a {SyntaxError} is raised.
class GraphQL::Parser < Parslet::Parser
  root(:document)
  rule(:document) { (
      space                |
      operation_definition |
      fragment_definition
    ).repeat(1).as(:document_parts)
  }

  # TODO: whitespace sensitive regarding `on`, eg `onFood`, see lookahead note in spec
  rule(:fragment_definition) {
    str("fragment").as(:fragment_keyword) >>
     space? >> name.as(:fragment_name) >>
     space? >> str("on") >> space? >> name.as(:type_condition) >>
     space? >> directives.maybe.as(:optional_directives).as(:directives) >>
     space? >> selections.as(:selections)
  }

  rule(:fragment_spread) {
    spread.as(:fragment_spread_keyword) >> space? >>
    name.as(:fragment_spread_name) >> space? >>
    directives.maybe.as(:optional_directives).as(:directives)
  }
  rule(:spread) { str("...") }
  # TODO: `on` bug, see spec
  rule(:inline_fragment) {
    spread.as(:fragment_spread_keyword) >> space? >>
    str("on ") >> name.as(:inline_fragment_type) >> space? >>
    directives.maybe.as(:optional_directives).as(:directives) >> space? >>
    selections.as(:selections)
  }

  rule(:operation_definition) { (unnamed_selections | named_operation_definition) }
  rule(:unnamed_selections) { selections.as(:unnamed_selections)}
  rule(:named_operation_definition) {
    operation_type.as(:operation_type) >> space? >>
    name.as(:name) >> space? >>
    operation_variable_definitions.maybe.as(:optional_variables).as(:variables) >> space? >>
    directives.maybe.as(:optional_directives).as(:directives) >> space? >>
    selections.as(:selections)
  }
  rule(:operation_type) { (str("query") | str("mutation")) }
  rule(:operation_variable_definitions) { str("(") >> space? >> (operation_variable_definition >> separator?).repeat(1) >> space? >> str(")") }
  rule(:operation_variable_definition) {
    value_variable.as(:variable_name) >> space? >>
    str(":") >> space? >>
    type.as(:variable_type) >> space? >>
    (str("=") >> space? >> value.as(:variable_default_value)).maybe.as(:variable_optional_default_value)}

  rule(:selection) { (inline_fragment | fragment_spread | field) >> space? >> separator? }
  rule(:selections) { str("{") >> space? >> selection.repeat(1) >> space? >> str("}")}

  rule(:field) {
    field_alias.maybe.as(:alias) >>
    name.as(:field_name) >>
    field_arguments.maybe.as(:optional_field_arguments).as(:field_arguments) >> space? >>
    directives.maybe.as(:optional_directives).as(:directives) >> space? >>
    selections.maybe.as(:optional_selections).as(:selections)
  }

  rule(:field_alias) { name.as(:alias_name) >> space? >> str(":") >> space? }
  rule(:field_arguments) { str("(") >> field_argument.repeat(1) >> str(")") }
  rule(:field_argument) { name.as(:field_argument_name) >> str(":") >> space? >> value.as(:field_argument_value) >> separator? }

  rule(:directives) { (directive >> separator?).repeat(1) }
  rule(:directive) {
    str("@") >> name.as(:directive_name) >>
    directive_arguments.maybe.as(:optional_directive_arguments).as(:directive_arguments)
  }
  rule(:directive_arguments) { str("(") >> directive_argument.repeat(1) >> str(")") }
  rule(:directive_argument) { name.as(:directive_argument_name) >> str(":") >> space? >> value.as(:directive_argument_value) >> separator? }

  rule(:type) { (non_null_type | list_type | type_name)}
  rule(:list_type) { str("[") >> type.as(:list_type) >> str("]")}
  rule(:non_null_type) { (list_type | type_name).as(:non_null_type) >> str("!") }
  rule(:type_name) { name.as(:type_name) }

  rule(:value) {(
    value_input_object  |
    value_float         |
    value_int           |
    value_string        |
    value_boolean       |
    value_array         |
    value_variable      |
    value_enum
  )}
  rule(:value_sign?) { match('[\-\+]').maybe }
  rule(:value_array) { (str("[") >> (value >> separator?).repeat(0) >> str("]")).as(:array) }
  rule(:value_boolean) { (str("true") | str("false")).as(:boolean) }
  rule(:value_float) { (value_sign? >> match('\d').repeat(1) >> str(".") >> match('\d').repeat(1) >> (match("[eE]") >> value_sign? >> match('\d').repeat(1)).maybe).as(:float) }
  rule(:value_input_object) { str("{") >> value_input_object_pair.repeat(1).as(:input_object) >> str("}") }
  rule(:value_input_object_pair) { space? >> name.as(:input_object_name) >>  space? >> str(":") >> space? >> value.as(:input_object_value) >> separator? }
  rule(:value_int) { (value_sign? >> match('\d').repeat(1)).as(:int) }
  # TODO: support unicode, escaped chars (match the spec)
  rule(:value_string) { str('"') >> match('[^\"]').repeat(1).as(:string) >> str('"')}
  rule(:value_enum) { name.as(:enum) }
  rule(:value_variable) { str("$") >> name.as(:variable) }

  rule(:separator?) { (space? >> str(",") >> space?).maybe }
  rule(:name) { match('[_A-Za-z]') >> match('[_0-9A-Za-z]').repeat(0) }
  rule(:comment) { str("#") >> match('[^\r\n]').repeat(0) }
  rule(:space) { (match('[\s\n]+') | comment).repeat(1) }
  rule(:space?) { space.maybe }
end
