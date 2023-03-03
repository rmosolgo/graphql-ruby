#include "graphql_ext.h"

VALUE GraphQL_Clexer_tokenize(VALUE self, VALUE query_string) {
  VALUE tokens = tokenize(query_string);
  return tokens;
}

#define ASSIGN_STATIC_VALUE_TOKEN(token_name, token_content) \
  rb_define_const(Clexer, #token_name, rb_str_new_cstr(token_content));

// Initialize the extension
void Init_graphql_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE Clexer = rb_define_module_under(GraphQL, "Clexer");
  rb_define_singleton_method(Clexer, "tokenize", GraphQL_Clexer_tokenize, 1);
  ASSIGN_STATIC_VALUE_TOKEN(ON, "on")
  ASSIGN_STATIC_VALUE_TOKEN(FRAGMENT, "fragment")
  ASSIGN_STATIC_VALUE_TOKEN(QUERY, "query")
  ASSIGN_STATIC_VALUE_TOKEN(MUTATION, "mutation")
  ASSIGN_STATIC_VALUE_TOKEN(SUBSCRIPTION, "subscription")
  ASSIGN_STATIC_VALUE_TOKEN(REPEATABLE, "repeatable")
  ASSIGN_STATIC_VALUE_TOKEN(RCURLY, "}")
  ASSIGN_STATIC_VALUE_TOKEN(LCURLY, "{")
  ASSIGN_STATIC_VALUE_TOKEN(RBRACKET, "]")
  ASSIGN_STATIC_VALUE_TOKEN(LBRACKET, "[")
  ASSIGN_STATIC_VALUE_TOKEN(RPAREN, ")")
  ASSIGN_STATIC_VALUE_TOKEN(LPAREN, "(")
  ASSIGN_STATIC_VALUE_TOKEN(COLON, ":")
  ASSIGN_STATIC_VALUE_TOKEN(VAR_SIGN, "$")
  ASSIGN_STATIC_VALUE_TOKEN(DIR_SIGN, "@")
  ASSIGN_STATIC_VALUE_TOKEN(ELLIPSIS, "...")
  ASSIGN_STATIC_VALUE_TOKEN(EQUALS, "=")
  ASSIGN_STATIC_VALUE_TOKEN(BANG, "!")
  ASSIGN_STATIC_VALUE_TOKEN(PIPE, "|")
  ASSIGN_STATIC_VALUE_TOKEN(AMP, "&")
  ASSIGN_STATIC_VALUE_TOKEN(SCHEMA, "schema")
  ASSIGN_STATIC_VALUE_TOKEN(SCALAR, "scalar")
  ASSIGN_STATIC_VALUE_TOKEN(TYPE, "type")
  ASSIGN_STATIC_VALUE_TOKEN(EXTEND, "extend")
  ASSIGN_STATIC_VALUE_TOKEN(IMPLEMENTS, "implements")
  ASSIGN_STATIC_VALUE_TOKEN(INTERFACE, "interface")
  ASSIGN_STATIC_VALUE_TOKEN(UNION, "union")
  ASSIGN_STATIC_VALUE_TOKEN(ENUM, "enum")
  ASSIGN_STATIC_VALUE_TOKEN(DIRECTIVE, "directive")
  ASSIGN_STATIC_VALUE_TOKEN(INPUT, "input")
}
