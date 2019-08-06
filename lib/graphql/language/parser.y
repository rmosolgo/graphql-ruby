class GraphQL::Language::Parser
rule
  target: document

  document: definitions_list { return make_node(:Document, definitions: val[0])}

  definitions_list:
      definition                    { return [val[0]]}
    | definitions_list definition   { val[0] << val[1] }

  definition:
      executable_definition
    | type_system_definition
    | type_system_extension

  executable_definition:
      operation_definition
    | fragment_definition

  operation_definition:
      operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set {
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
    | LCURLY selection_list RCURLY {
        return make_node(
          :OperationDefinition, {
            operation_type: "query",
            selections: val[1],
            position_source: val[0],
          }
        )
      }
    | LCURLY RCURLY {
        return make_node(
          :OperationDefinition, {
            operation_type: "query",
            selections: [],
            position_source: val[0],
          }
        )
      }

  operation_type:
      QUERY
    | MUTATION
    | SUBSCRIPTION

  operation_name_opt:
      /* none */ { return nil }
    | name

  variable_definitions_opt:
      /* none */                              { return EMPTY_ARRAY }
    | LPAREN variable_definitions_list RPAREN { return val[1] }

  variable_definitions_list:
      variable_definition                           { return [val[0]] }
    | variable_definitions_list variable_definition { val[0] << val[1] }

  variable_definition:
      VAR_SIGN name COLON type default_value_opt {
        return make_node(:VariableDefinition, {
          name: val[1],
          type: val[3],
          default_value: val[4],
          position_source: val[0],
        })
      }

  type:
      name                   { return make_node(:TypeName, name: val[0])}
    | type BANG              { return make_node(:NonNullType, of_type: val[0]) }
    | LBRACKET type RBRACKET { return make_node(:ListType, of_type: val[1]) }

  default_value_opt:
      /* none */            { return nil }
    | EQUALS literal_value  { return val[1] }

  selection_set:
      LCURLY selection_list RCURLY { return val[1] }

  selection_set_opt:
      /* none */    { return EMPTY_ARRAY }
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
      name_without_on
    | ON

  schema_keyword:
      SCHEMA
    | SCALAR
    | TYPE
    | IMPLEMENTS
    | INTERFACE
    | UNION
    | ENUM
    | INPUT
    | DIRECTIVE

  name_without_on:
      IDENTIFIER
    | FRAGMENT
    | TRUE
    | FALSE
    | operation_type
    | schema_keyword

  enum_name: /* any identifier, but not "true", "false" or "null" */
      IDENTIFIER
    | FRAGMENT
    | ON
    | operation_type
    | schema_keyword

  enum_value_definition:
    description_opt enum_name directives_list_opt { return make_node(:EnumValueDefinition, name: val[1], directives: val[2], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1]) }

  enum_value_definitions:
      enum_value_definition                        { return [val[0]] }
    | enum_value_definitions enum_value_definition { return val[0] << val[1] }

  arguments_opt:
      /* none */                    { return EMPTY_ARRAY }
    | LPAREN RPAREN                 { return EMPTY_ARRAY }
    | LPAREN arguments_list RPAREN  { return val[1] }

  arguments_list:
      argument                { return [val[0]] }
    | arguments_list argument { val[0] << val[1] }

  argument:
      name COLON input_value { return make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}

  literal_value:
      FLOAT       { return val[0].to_f }
    | INT         { return val[0].to_i }
    | STRING      { return val[0].to_s }
    | TRUE        { return true }
    | FALSE       { return false }
    | null_value
    | enum_value
    | list_value
    | object_literal_value

  input_value:
    | literal_value
    | variable
    | object_value

  null_value: NULL { return make_node(:NullValue, name: val[0], position_source: val[0]) }
  variable: VAR_SIGN name { return make_node(:VariableIdentifier, name: val[1], position_source: val[0]) }

  list_value:
      LBRACKET RBRACKET                 { return EMPTY_ARRAY }
    | LBRACKET list_value_list RBRACKET { return val[1] }

  list_value_list:
      input_value                 { return [val[0]] }
    | list_value_list input_value { val[0] << val[1] }

  object_value:
      LCURLY RCURLY                   { return make_node(:InputObject, arguments: [], position_source: val[0])}
    | LCURLY object_value_list RCURLY { return make_node(:InputObject, arguments: val[1], position_source: val[0])}

  object_value_list:
      object_value_field                    { return [val[0]] }
    | object_value_list object_value_field  { val[0] << val[1] }

  object_value_field:
      name COLON input_value { return make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}

  /* like the previous, but with literals only: */
  object_literal_value:
      LCURLY RCURLY                           { return make_node(:InputObject, arguments: [], position_source: val[0])}
    | LCURLY object_literal_value_list RCURLY { return make_node(:InputObject, arguments: val[1], position_source: val[0])}

  object_literal_value_list:
      object_literal_value_field                            { return [val[0]] }
    | object_literal_value_list object_literal_value_field  { val[0] << val[1] }

  object_literal_value_field:
      name COLON literal_value { return make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}

  enum_value: enum_name { return make_node(:Enum, name: val[0], position_source: val[0]) }

  directives_list_opt:
      /* none */      { return  EMPTY_ARRAY }
    | directives_list

  directives_list:
      directive                 { return [val[0]] }
    | directives_list directive { val[0] << val[1] }

  directive: DIR_SIGN name arguments_opt { return make_node(:Directive, name: val[1], arguments: val[2], position_source: val[0]) }

  fragment_spread:
      ELLIPSIS name_without_on directives_list_opt { return make_node(:FragmentSpread, name: val[1], directives: val[2], position_source: val[0]) }

  inline_fragment:
      ELLIPSIS ON type directives_list_opt selection_set {
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
    FRAGMENT fragment_name_opt ON type directives_list_opt selection_set {
      return make_node(:FragmentDefinition, {
          name:       val[1],
          type:       val[3],
          directives: val[4],
          selections: val[5],
          position_source: val[0],
        }
      )
    }

  fragment_name_opt:
      /* none */ { return nil }
    | name_without_on

  type_system_definition:
     schema_definition
   | type_definition
   | directive_definition

  schema_definition:
      SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY { return make_node(:SchemaDefinition, position_source: val[0], definition_line: val[0].line, directives: val[1], **val[3]) }

  operation_type_definition_list:
      operation_type_definition
    | operation_type_definition_list operation_type_definition { return val[0].merge(val[1]) }

  operation_type_definition:
      operation_type COLON name { return { val[0].to_s.to_sym => val[2] } }

  type_definition:
      scalar_type_definition
    | object_type_definition
    | interface_type_definition
    | union_type_definition
    | enum_type_definition
    | input_object_type_definition

  type_system_extension:
      schema_extension
    | type_extension

  schema_extension:
      EXTEND SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY { return make_node(:SchemaExtension, position_source: val[0], directives: val[2], **val[4]) }
    | EXTEND SCHEMA directives_list { return make_node(:SchemaExtension, position_source: val[0], directives: val[2]) }

  type_extension:
      scalar_type_extension
    | object_type_extension
    | interface_type_extension
    | union_type_extension
    | enum_type_extension
    | input_object_type_extension

  scalar_type_extension: EXTEND SCALAR name directives_list { return make_node(:ScalarTypeExtension, name: val[2], directives: val[3], position_source: val[0]) }

  object_type_extension:
      /* TODO - This first one shouldn't be necessary but parser is getting confused */
      EXTEND TYPE name implements LCURLY field_definition_list RCURLY { return make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: [], fields: val[5], position_source: val[0]) }
    | EXTEND TYPE name implements_opt directives_list_opt LCURLY field_definition_list RCURLY { return make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: val[4], fields: val[6], position_source: val[0]) }
    | EXTEND TYPE name implements_opt directives_list { return make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: val[4], fields: [], position_source: val[0]) }
    | EXTEND TYPE name implements { return make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: [], fields: [], position_source: val[0]) }

  interface_type_extension:
      EXTEND INTERFACE name directives_list_opt LCURLY field_definition_list RCURLY { return make_node(:InterfaceTypeExtension, name: val[2], directives: val[3], fields: val[5], position_source: val[0]) }
    | EXTEND INTERFACE name directives_list { return make_node(:InterfaceTypeExtension, name: val[2], directives: val[3], fields: [], position_source: val[0]) }

  union_type_extension:
      EXTEND UNION name directives_list_opt EQUALS union_members { return make_node(:UnionTypeExtension, name: val[2], directives: val[3], types: val[5], position_source: val[0]) }
    | EXTEND UNION name directives_list { return make_node(:UnionTypeExtension, name: val[2], directives: val[3], types: [], position_source: val[0]) }

  enum_type_extension:
      EXTEND ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY { return make_node(:EnumTypeExtension, name: val[2], directives: val[3], values: val[5], position_source: val[0]) }
    | EXTEND ENUM name directives_list { return make_node(:EnumTypeExtension, name: val[2], directives: val[3], values: [], position_source: val[0]) }

  input_object_type_extension:
      EXTEND INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY { return make_node(:InputObjectTypeExtension, name: val[2], directives: val[3], fields: val[5], position_source: val[0]) }
    | EXTEND INPUT name directives_list { return make_node(:InputObjectTypeExtension, name: val[2], directives: val[3], fields: [], position_source: val[0]) }

  description: STRING

  description_opt:
      /* none */
    | description

  scalar_type_definition:
      description_opt SCALAR name directives_list_opt {
        return make_node(:ScalarTypeDefinition, name: val[2], directives: val[3], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  object_type_definition:
      description_opt TYPE name implements_opt directives_list_opt LCURLY field_definition_list RCURLY {
        return make_node(:ObjectTypeDefinition, name: val[2], interfaces: val[3], directives: val[4], fields: val[6], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  implements_opt:
      /* none */ { return EMPTY_ARRAY }
    | implements

  implements:
      IMPLEMENTS AMP interfaces_list { return val[2] }
    | IMPLEMENTS interfaces_list { return val[1] }
    | IMPLEMENTS legacy_interfaces_list { return val[1] }

  interfaces_list:
      name                     { return [make_node(:TypeName, name: val[0], position_source: val[0])] }
    | interfaces_list AMP name { val[0] << make_node(:TypeName, name: val[2], position_source: val[2]) }

  legacy_interfaces_list:
      name                        { return [make_node(:TypeName, name: val[0], position_source: val[0])] }
    | legacy_interfaces_list name { val[0] << make_node(:TypeName, name: val[1], position_source: val[1]) }

  input_value_definition:
      description_opt name COLON type default_value_opt directives_list_opt {
        return make_node(:InputValueDefinition, name: val[1], type: val[3], default_value: val[4], directives: val[5], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  input_value_definition_list:
      input_value_definition                             { return [val[0]] }
    | input_value_definition_list input_value_definition { val[0] << val[1] }

  arguments_definitions_opt:
      /* none */ { return EMPTY_ARRAY }
    | LPAREN input_value_definition_list RPAREN { return val[1] }

  field_definition:
      description_opt name arguments_definitions_opt COLON type directives_list_opt {
        return make_node(:FieldDefinition, name: val[1], arguments: val[2], type: val[4], directives: val[5], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  field_definition_list:
    /* none */ { return EMPTY_ARRAY }
    | field_definition                       { return [val[0]] }
    | field_definition_list field_definition { val[0] << val[1] }

  interface_type_definition:
      description_opt INTERFACE name directives_list_opt LCURLY field_definition_list RCURLY {
        return make_node(:InterfaceTypeDefinition, name: val[2], directives: val[3], fields: val[5], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  union_members:
      name                    { return [make_node(:TypeName, name: val[0], position_source: val[0])]}
    | union_members PIPE name { val[0] << make_node(:TypeName, name: val[2], position_source: val[2]) }

  union_type_definition:
      description_opt UNION name directives_list_opt EQUALS union_members {
        return make_node(:UnionTypeDefinition, name: val[2], directives: val[3], types: val[5], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  enum_type_definition:
      description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY {
         return make_node(:EnumTypeDefinition, name: val[2], directives: val[3], values: val[5], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  input_object_type_definition:
      description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY {
        return make_node(:InputObjectTypeDefinition, name: val[2], directives: val[3], fields: val[5], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  directive_definition:
      description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt ON directive_locations {
        return make_node(:DirectiveDefinition, name: val[3], arguments: val[4], locations: val[6], description: val[0] || get_description(val[1]), definition_line: val[1].line, position_source: val[0] || val[1])
      }

  directive_locations:
      name                          { return [make_node(:DirectiveLocation, name: val[0].to_s, position_source: val[0])] }
    | directive_locations PIPE name { val[0] << make_node(:DirectiveLocation, name: val[2].to_s, position_source: val[2]) }
end

---- header ----


---- inner ----

EMPTY_ARRAY = [].freeze

def initialize(query_string, filename:, tracer: Tracing::NullTracer)
  raise GraphQL::ParseError.new("No query string was present", nil, nil, query_string) if query_string.nil?
  @query_string = query_string
  @filename = filename
  @tracer = tracer
end

def parse_document
  @document ||= begin
    # Break the string into tokens
    @tracer.trace("lex", {query_string: @query_string}) do
      @tokens ||= GraphQL.scan(@query_string)
    end
    # From the tokens, build an AST
    @tracer.trace("parse", {query_string: @query_string}) do
      if @tokens.empty?
        make_node(:Document, definitions: [], filename: @filename)
      else
        do_parse
      end
    end
  end
end

def self.parse(query_string, filename: nil, tracer: GraphQL::Tracing::NullTracer)
  self.new(query_string, filename: filename, tracer: tracer).parse_document
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

def get_description(token)
  comments = []

  loop do
    prev_token = token
    token = token.prev_token

    break if token.nil?
    break if token.name != :COMMENT
    break if prev_token.line != token.line + 1

    comments.unshift(token.to_s.sub(/^#\s*/, ""))
  end

  return nil if comments.empty?

  comments.join("\n")
end

def on_error(parser_token_id, lexer_token, vstack)
  if lexer_token == "$" || lexer_token == nil
    raise GraphQL::ParseError.new("Unexpected end of document", nil, nil, @query_string, filename: @filename)
  else
    parser_token_name = token_to_str(parser_token_id)
    if parser_token_name.nil?
      raise GraphQL::ParseError.new("Parse Error on unknown token: {token_id: #{parser_token_id}, lexer_token: #{lexer_token}} from #{@query_string}", nil, nil, @query_string, filename: @filename)
    else
      line, col = lexer_token.line_and_column
      if lexer_token.name == :BAD_UNICODE_ESCAPE
        raise GraphQL::ParseError.new("Parse error on bad Unicode escape sequence: #{lexer_token.to_s.inspect} (#{parser_token_name}) at [#{line}, #{col}]", line, col, @query_string, filename: @filename)
      else
        raise GraphQL::ParseError.new("Parse error on #{lexer_token.to_s.inspect} (#{parser_token_name}) at [#{line}, #{col}]", line, col, @query_string, filename: @filename)
      end
    end
  end
end

def make_node(node_name, assigns)
  assigns.each do |key, value|
    if key != :position_source && value.is_a?(GraphQL::Language::Token)
      assigns[key] = value.to_s
    end
  end

  assigns[:filename] = @filename

  GraphQL::Language::Nodes.const_get(node_name).new(assigns)
end
