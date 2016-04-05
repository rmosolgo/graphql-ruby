class GraphQL::Language::Parser
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
            position_source: val[0],
          }
        )
      }
    | selection_set {
        return make_node(
          :OperationDefinition, {
            operation_type: "query",
            selections: val[0],
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
          position_source: val[0],
        })
      }

  variable_definition_type_name:
      name                                            { return make_node(:TypeName, name: val[0])}
    | variable_definition_type_name BANG              { return make_node(:NonNullType, of_type: val[0]) }
    | RBRACKET variable_definition_type_name LBRACKET { return make_node(:ListType, of_type: val[1]) }

  variable_definition_default_value_opt:
      /* none */          { return nil }
    | EQUALS input_value  { return val[1] }

  selection_set:
      RCURLY LCURLY                { return [] }
    | RCURLY selection_list LCURLY { return val[1] }

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
                position_source: val[0],
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
                position_source: val[0],
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
    | RPAREN LPAREN                 { return [] }
    | RPAREN arguments_list LPAREN  { return val[1] }

  arguments_list:
      argument                { return [val[0]] }
    | arguments_list argument { val[0] << val[1] }

  argument:
      name COLON input_value { return make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}

  input_value:
      FLOAT       { return val[0].to_f }
    | INT         { return val[0].to_i }
    | STRING      { return val[0].to_s }
    | TRUE        { return true }
    | FALSE       { return false }
    | variable
    | list_value
    | object_value
    | enum_value

  variable: VAR_SIGN name { return make_node(:VariableIdentifier, name: val[1], position_source: val[0]) }

  list_value:
      RBRACKET LBRACKET                 { return [] }
    | RBRACKET list_value_list LBRACKET { return val[1] }

  list_value_list:
      input_value                 { return [val[0]] }
    | list_value_list input_value { val[0] << val[1] }

  object_value:
      RCURLY LCURLY                   { return make_node(:InputObject, arguments: [], position_source: val[0])}
    | RCURLY object_value_list LCURLY { return make_node(:InputObject, arguments: val[1], position_source: val[0])}

  object_value_list:
      object_value_field                    { return [val[0]] }
    | object_value_list object_value_field  { val[0] << val[1] }

  object_value_field:
      name COLON input_value { return make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}

  enum_value: IDENTIFIER { return make_node(:Enum, name: val[0], position_source: val[0])}

  directives_list_opt:
      /* none */      { return [] }
    | directives_list

  directives_list:
      directive                 { return [val[0]] }
    | directives_list directive { val[0] << val[1] }

  directive: DIR_SIGN name arguments_opt { return make_node(:Directive, name: val[1], arguments: val[2], position_source: val[0]) }

  fragment_spread:
      ELLIPSIS name directives_list_opt { return make_node(:FragmentSpread, name: val[1], directives: val[2], position_source: val[0]) }

  inline_fragment:
      ELLIPSIS ON name directives_list_opt selection_set {
        return make_node(:InlineFragment, {
          type: val[2],
          directives: val[3],
          selections: val[4],
          position_source: val[0]
        })
      }
    | ELLIPSIS directives_list_opt selection_set {
        return make_node(:InlineFragment, {
          type: nil,
          directives: val[1],
          selections: val[2],
          position_source: val[0]
        })
      }

  fragment_definition:
    FRAGMENT name ON name directives_list_opt selection_set {
      return make_node(:FragmentDefinition, {
          name:       val[1],
          type:       val[3],
          directives: val[4],
          selections: val[5],
          position_source: val[0],
        }
      )
    }
end

---- header ----


---- inner ----

def initialize(query_string)
  @query_string = query_string
end

def parse_document
  @document ||= begin
    @tokens ||= GraphQL::Language::Lexer.tokenize(@query_string)
    if @tokens.none?
      make_node(:Document, definitions: [])
    else
      do_parse
    end
  end
end

def self.parse(query_string)
  self.new(query_string).parse_document
end

private

def next_token
  lexer_token = @tokens.shift
  if lexer_token.nil?
    nil
  else
    [lexer_token.name, lexer_token]
  end
end

def on_error(parser_token_id, lexer_token, vstack)
  if lexer_token == "$"
    raise GraphQL::ParseError.new("Unexpected end of document", nil, nil, @query_string)
  else
    parser_token_name = token_to_str(parser_token_id)
    if parser_token_name.nil?
      raise GraphQL::ParseError.new("Parse Error on unknown token: {token_id: #{parser_token_id}, lexer_token: #{lexer_token}} from #{@query_string}", nil, nil, @query_string)
    else
      line, col = lexer_token.line_and_column
      raise GraphQL::ParseError.new("Parse error on #{lexer_token.to_s.inspect} (#{parser_token_name}) at [#{line}, #{col}]", line, col, @query_string)
    end
  end
end

def make_node(node_name, assigns)
  assigns.each do |key, value|
    if key != :position_source && value.is_a?(GraphQL::Language::Token)
      assigns[key] = value.to_s
    end
  end

  GraphQL::Language::Nodes.const_get(node_name).new(assigns)
end
