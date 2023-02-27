#include "graphql_ext.h"
#include "lexer.c"

VALUE GraphQL_Clexer_tokenize(VALUE self, VALUE query_string) {
  return query_string;
}

// Initialize the extension
void Init_graphql_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE Clexer = rb_define_module_under(GraphQL, "Clexer");
  rb_define_singleton_method(Clexer, "tokenize", GraphQL_Clexer_tokenize, 1);
}
