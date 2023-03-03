%require "3.8"
%define api.pure full

%{
// C Declarations
#include <ruby.h>
#define YYSTYPE VALUE
int yylex(YYSTYPE *, VALUE);
void yyerror(VALUE, const char*);

%}

%param {VALUE parser}

// YACC Declarations
%token AMP 200
%token BANG 201
%token COLON 202
%token DIRECTIVE 203
%token DIR_SIGN 204
%token ENUM 205
%token ELLIPSIS 206
%token EQUALS 207
%token EXTEND 208
%token FALSE_LITERAL 209
%token FLOAT 210
%token FRAGMENT 211
%token IDENTIFIER 212
%token INPUT 213
%token IMPLEMENTS 214
%token INT 215
%token INTERFACE 216
%token LBRACKET 217
%token LCURLY 218
%token LPAREN 219
%token MUTATION 220
%token NULL_LITERAL 221
%token ON 222
%token PIPE 223
%token QUERY 224
%token RBRACKET 225
%token RCURLY 226
%token REPEATABLE 227
%token RPAREN 228
%token SCALAR 229
%token SCHEMA 230
%token STRING 231
%token SUBSCRIPTION 232
%token TRUE_LITERAL 233
%token TYPE_LITERAL 234
%token UNION 235
%token VAR_SIGN 236

%%

  // YACC Rules
  start: document { rb_ivar_set(parser, rb_intern("result"), $1); }

  document: definitions_list { $$ = $1; }

  definitions_list:
      definition                    { $$ = rb_ary_new_from_args(1, $1); }
    | definitions_list definition   { rb_ary_push($$, $2); }

  definition:
    executable_definition
    /* TODO
    | type_system_definition
    | type_system_extension */

  executable_definition:
      operation_definition
    /* TODO | fragment_definition  */


  operation_definition:
      /*
      operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set {
        result = make_node(
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
    | */
    LCURLY selection_list RCURLY {
        $$ = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("OperationDefinition")),
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_str_new_cstr("query"), // TODO static string
          $2
        );
      }
    | LCURLY RCURLY {
        $$ = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("OperationDefinition")),
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_str_new_cstr("query"), // TODO static string
          rb_ary_new()
        );
      }

  selection_list:
      selection                 { $$ = rb_ary_new_from_args(1, $1); }
    | selection_list selection  { rb_ary_push($$, $2); }

  selection:
      field
    /* TODO | fragment_spread
    | inline_fragment */

  selection_set:
      LCURLY selection_list RCURLY { $$ = $2; }

  selection_set_opt:
      /* none */    { $$ = rb_ary_new(); }
    | selection_set



  field:
    name COLON name arguments_opt directives_list_opt selection_set_opt {
      $$ = rb_ary_new_from_args(
        8,
        rb_id2sym(rb_intern("Field")),
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        rb_ary_entry($1, 3), // alias
        rb_ary_entry($3, 3), // name
        $4, // args
        $5, // directives
        $6 // subselections
      );
    }
    | name arguments_opt directives_list_opt selection_set_opt {
      $$ = rb_ary_new_from_args(
        8,
        rb_id2sym(rb_intern("Field")),
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        Qnil, // alias
        rb_ary_entry($1, 3), // name
        $2, // args
        $3, // directives
        $4 // subselections
      );
    }

  arguments_opt:
      /* none */                    { $$ = Qnil; }
    | LPAREN arguments_list RPAREN  { $$ = $2; }

  arguments_list:
      argument                { $$ = rb_ary_new_from_args(1, $1); }
    | arguments_list argument { rb_ary_push($$, $2); }

  argument:
      name COLON input_value {
        $$ = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("Argument")),
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          $3
        );
      }

  literal_value:
      FLOAT       { $$ = rb_funcall(rb_ary_entry($1, 3), rb_intern("to_f"), 0); }
    | INT         { $$ = rb_funcall(rb_ary_entry($1, 3), rb_intern("to_i"), 0); }
    | STRING      { $$ = rb_ary_entry($1, 3); }
    | TRUE_LITERAL        { $$ = Qtrue; }
    | FALSE_LITERAL       { $$ = Qfalse; }
    | null_value
    | enum_value
    | list_value
    | object_literal_value

  input_value:
    literal_value
    | variable
    | object_value

  null_value: NULL_LITERAL {
    $$ = rb_ary_new_from_args(4,
      rb_id2sym(rb_intern("NullValue")),
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($1, 3)
    );
  }

  variable: VAR_SIGN name {
    $$ = rb_ary_new_from_args(4,
      rb_id2sym(rb_intern("VariableIdentifier")),
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($1, 3)
    );
  }

  list_value:
      LBRACKET RBRACKET                 { $$ = rb_ary_new(); } // TODO get a empty array?
    | LBRACKET list_value_list RBRACKET { $$ = $2; }

  list_value_list:
      input_value                 { $$ = rb_ary_new_from_args(1, $1); }
    | list_value_list input_value { rb_ary_push($$, $2); }

  enum_name: /* any identifier, but not "true", "false" or "null" */
      IDENTIFIER
    | FRAGMENT
    | REPEATABLE
    | ON
    | operation_type
    | schema_keyword

  enum_value: enum_name {
    $$ = rb_ary_new_from_args(4,
      rb_id2sym(rb_intern("Enum")),
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($1, 3)
    );
  }

  object_value:
    | LCURLY object_value_list_opt RCURLY {
      $$ = rb_ary_new_from_args(4,
        rb_id2sym(rb_intern("InputObject")),
        rb_ary_entry($1, 1),
        rb_ary_entry($1, 2),
        $2
      );
    }

  object_value_list_opt:
      /* nothing */     { $$ = rb_ary_new(); }
    | object_value_list

  object_value_list:
      object_value_field                    { $$ = rb_ary_new_from_args(1, $1); }
    | object_value_list object_value_field  { rb_ary_push($$, $2); }

  object_value_field:
      name COLON input_value {
        $$ = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("Argument")),
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          rb_ary_entry($3, 3)
        );
      }

  /* like the previous, but with literals only: */
  object_literal_value:
      LCURLY object_literal_value_list_opt RCURLY {
        $$ = rb_ary_new_from_args(4,
          rb_id2sym(rb_intern("InputObject")),
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          $2
        );
      }

  object_literal_value_list_opt:
      /* nothing */             { $$ = rb_ary_new(); }
    | object_literal_value_list

  object_literal_value_list:
      object_literal_value_field                            { $$ = rb_ary_new_from_args(1, $1); }
    | object_literal_value_list object_literal_value_field  { rb_ary_push($$, $2); }

  object_literal_value_field:
      name COLON literal_value {
        $$ = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("Argument")),
          rb_ary_entry($1, 1),
          rb_ary_entry($1, 2),
          rb_ary_entry($1, 3),
          rb_ary_entry($3, 3)
        );
      }


  directives_list_opt:
      /* none */      { $$ = rb_ary_new(); }
    | directives_list

  directives_list:
      directive                 { $$ = rb_ary_new_from_args(1, $1); }
    | directives_list directive { rb_ary_push($$, $2); }

  directive: DIR_SIGN name arguments_opt {
    $$ = rb_ary_new_from_args(5,
      rb_id2sym(rb_intern("Directive")),
      rb_ary_entry($1, 1),
      rb_ary_entry($1, 2),
      rb_ary_entry($2, 3),
      $3
    );
  }

  name:
      name_without_on
    | ON

  operation_type:
      QUERY
    | MUTATION
    | SUBSCRIPTION

 schema_keyword:
      SCHEMA
    | SCALAR
    | TYPE_LITERAL
    | IMPLEMENTS
    | INTERFACE
    | UNION
    | ENUM
    | INPUT
    | DIRECTIVE

  name_without_on:
      IDENTIFIER
    | FRAGMENT
    | REPEATABLE
    | TRUE_LITERAL
    | FALSE_LITERAL
    | operation_type
    | schema_keyword
%%

// Custom functions
int yylex (YYSTYPE *lvalp, VALUE parser) {
  int next_token_idx = FIX2INT(rb_ivar_get(parser, rb_intern("current_token")));
  VALUE tokens = rb_ivar_get(parser, rb_intern("tokens"));
  VALUE next_token = rb_ary_entry(tokens, next_token_idx);

  if (!RB_TEST(next_token)) {
    return YYEOF;
  }

  rb_ivar_set(parser, rb_intern("current_token"), INT2FIX(next_token_idx + 1));
  VALUE token_type_rb_int = rb_ary_entry(next_token, 5);
  int next_token_type = FIX2INT(token_type_rb_int);

  *lvalp = next_token;
  return next_token_type;
}

void yyerror(VALUE tokens, const char *msg) {
}
