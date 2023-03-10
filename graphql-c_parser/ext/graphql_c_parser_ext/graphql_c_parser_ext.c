#include "graphql_c_parser_ext.h"

VALUE GraphQL_Language_CLexer_tokenize(VALUE self, VALUE query_string) {
  VALUE tokens = tokenize(query_string);
  return tokens;
}

VALUE GraphQL_Language_CParser_parse(VALUE self, VALUE query_string) {
  VALUE tokens = tokenize(query_string);
  VALUE parser = rb_class_new(self);
  rb_ivar_set(parser, rb_intern("tokens"), tokens);
  rb_ivar_set(parser, rb_intern("current_token"), INT2FIX(0));
  rb_ivar_set(parser, rb_intern("result"), Qnil);
  yyparse(parser);
  return rb_ivar_get(parser, rb_intern("result"));
}

void Init_graphql_c_parser_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE Language = rb_define_module_under(GraphQL, "Language");
  VALUE CLexer = rb_define_module_under(Language, "CLexer");
  rb_define_singleton_method(CLexer, "tokenize", GraphQL_Language_CLexer_tokenize, 1);
  setup_static_token_variables();

  VALUE CParser = rb_define_class_under(Language, "CParser", rb_cObject);
  rb_define_singleton_method(CParser, "parse", GraphQL_Language_CParser_parse, 1);
  initialize_node_class_variables();
}
