#include "graphql_ext.h"
#include "lexer.h"

VALUE GraphQL_Clexer_tokenize(VALUE self, VALUE query_string) {
  VALUE tokens = tokenize(query_string);
  return tokens;
}

// Initialize the extension
void Init_graphql_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE Clexer = rb_define_module_under(GraphQL, "Clexer");
  rb_define_singleton_method(Clexer, "tokenize", GraphQL_Clexer_tokenize, 1);
}
