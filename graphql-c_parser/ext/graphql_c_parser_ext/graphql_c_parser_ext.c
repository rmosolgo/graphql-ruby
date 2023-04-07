#include "graphql_c_parser_ext.h"

VALUE GraphQL_CParser_Lexer_tokenize(VALUE self, VALUE query_string) {
  return tokenize(query_string);
}

VALUE GraphQL_CParser_Parser_c_parse(VALUE self) {
  yyparse(self, rb_ivar_get(self, rb_intern("@filename")));
  return Qnil;
}

void Init_graphql_c_parser_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE CParser = rb_define_module_under(GraphQL, "CParser");
  VALUE Lexer = rb_define_module_under(CParser, "Lexer");
  rb_define_singleton_method(Lexer, "tokenize", GraphQL_CParser_Lexer_tokenize, 1);
  setup_static_token_variables();

  VALUE Parser = rb_define_class_under(CParser, "Parser", rb_cObject);
  rb_define_method(Parser, "c_parse", GraphQL_CParser_Parser_c_parse, 0);
  initialize_node_class_variables();
}
