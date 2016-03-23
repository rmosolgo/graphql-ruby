class GraphQL::Language::RaccParser
rule
  target: document

  document: definitions_list { return make_node(:Document, definitions: val[0])}

  definitions_list:
      definition                    { return [val[0]]}
    | definitions_list definition   { val[0] << val[1] }

  definition:
      operation_definition
    | fragment_definition

  operation_definition:
      name operation_name_opt variable_definitions_opt directives_list_opt selection_set {
        return  make_node(
          :OperationDefinition, {
            operation_type: val[0],
            name:           val[1],
            variables:      val[2],
            directives:     val[3],
            selections:     val[4],
          }
        )
      }
    | selection_set {
        return make_node(
          :OperationDefinition, {
            operation_type: "query",
            selections: val[0]
          }
        )
      }

  operation_name_opt:
      /* none */ { return nil }
    | name

  variable_definitions_opt:
      /* none */                              { return [] }
    | RPAREN variable_definitions_list LPAREN { return val[1] }

  variable_definitions_list:
      variable_definition                           { return [val[0]] }
    | variable_definitions_list variable_definition { val[0] << val[1] }

  variable_definition:
      VAR_SIGN name COLON variable_definition_type_name variable_definition_default_value_opt {
        return make_node(:VariableDefinition, {
          name: val[1],
          type: val[3],
          default_value: val[4],
        })
      }

  variable_definition_type_name:
      name                                            { return make_node(:TypeName, name: val[0])}
    | variable_definition_type_name BANG              { return make_node(:NonNullType, of_type: val[0]) }
    | RBRACKET variable_definition_type_name LBRACKET { return make_node(:ListType, of_type: val[1]) }

  variable_definition_default_value_opt:
      /* none */          { return nil }
    | EQUALS input_value  { return val[1] }

  selection_set: RCURLY selection_list LCURLY { return val[1] }

  selection_set_opt:
      /* none */    { return [] }
    | selection_set { return val[0] }

  selection_list:
      selection                 { return [result] }
    | selection_list selection  { val[0] << val[1] }

  selection:
      field
    | fragment_spread
    | inline_fragment

  field:
      name arguments_opt directives_list_opt selection_set_opt {
            return make_node(
              :Field, {
                name:         val[0],
                arguments:    val[1],
                directives:   val[2],
                selections:   val[3],
              }
            )
          }
    | name COLON name arguments_opt directives_list_opt selection_set_opt {
            return make_node(
              :Field, {
                alias:        val[0],
                name:         val[2],
                arguments:    val[3],
                directives:   val[4],
                selections:   val[5],
              }
            )
          }

  name:
      IDENTIFIER
    | FRAGMENT
    | TRUE
    | FALSE
    | ON

  arguments_opt:
      /* none */                    { return [] }
    | RPAREN arguments_list LPAREN  { return val[1] }

  arguments_list:
      argument                { return [val[0]] }
    | arguments_list argument { val[0] << val[1] }

  argument:
      name COLON input_value { return make_node(:Argument, name: val[0], value: val[2])}

  input_value:
      FLOAT       { return val[0].to_f }
    | INT         { return val[0].to_i }
    | STRING      { return val[0] }
    | TRUE        { return true }
    | FALSE       { return false }
    | variable
    | list_value
    | object_value
    | enum_value

  variable: VAR_SIGN name { return make_node(:VariableIdentifier, name: val[1]) }

  list_value:
      RBRACKET LBRACKET                 { return [] }
    | RBRACKET list_value_list LBRACKET { return val[1] }

  list_value_list:
      input_value                 { return [val[0]] }
    | list_value_list input_value { val[0] << val[1] }

  object_value:
      RCURLY LCURLY                   { return make_node(:InputObject, arguments: [])}
    | RCURLY object_value_list LCURLY { return make_node(:InputObject, arguments: val[1])}

  object_value_list:
      object_value_field                    { return [val[0]] }
    | object_value_list object_value_field  { val[0] << val[1] }

  object_value_field:
      name COLON input_value { return make_node(:Argument, name: val[0], value: val[2])}

  enum_value: IDENTIFIER { return make_node(:Enum, name: val[0])}

  directives_list_opt:
      /* none */      { return [] }
    | directives_list

  directives_list:
      directive                 { return [val[0]] }
    | directives_list directive { val[0] << val[1] }

  directive: DIR_SIGN name arguments_opt { return make_node(:Directive, name: val[1], arguments: val[2]) }

  fragment_spread:
      ELLIPSIS name directives_list_opt { return make_node(:FragmentSpread, name: val[1], directives: val[2]) }

  inline_fragment:
    ELLIPSIS ON name directives_list_opt selection_set {
      return make_node(:InlineFragment, {
        type: val[2],
        directives: val[3],
        selections: val[4]
      })
    }

  fragment_definition:
    FRAGMENT name ON name directives_list_opt selection_set {
      return make_node(:FragmentDefinition, {
          name:       val[1],
          type:       val[3],
          directives: val[4],
          selections: val[5],
        }
      )
    }
end

---- header ----

require_relative './lex.rex'

---- inner ----

def make_node(node_name, assigns = {})
  GraphQL::Language::Nodes.const_get(node_name).new(assigns)
end

def self.parse(query_string)
  self.new.scan_str(query_string)
rescue Racc::ParseError => error
  raise GraphQL::ParseError.new(error.message, nil, nil, query_string)
end
