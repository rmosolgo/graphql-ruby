#include "graphql_ext.h"

VALUE GraphQL_Language_CLexer_tokenize(VALUE self, VALUE query_string) {
  VALUE tokens = tokenize(query_string);
  return tokens;
}

void Init_graphql_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE Language = rb_define_module_under(GraphQL, "Language");
  VALUE CLexer = rb_define_module_under(Language, "CLexer");
  rb_define_singleton_method(CLexer, "tokenize", GraphQL_Language_CLexer_tokenize, 1);
  setup_static_token_variables();
}
