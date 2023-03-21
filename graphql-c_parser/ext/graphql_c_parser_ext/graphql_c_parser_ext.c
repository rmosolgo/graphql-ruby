#include "graphql_c_parser_ext.h"

VALUE GraphQL_Language_CLexer_tokenize(VALUE self, VALUE query_string) {
  return tokenize(query_string);
}

VALUE call_tokenize(VALUE yield_arg, VALUE query_string, int argc, VALUE* argv, VALUE block_arg) {
  return tokenize(query_string);
}

VALUE call_yyparse(VALUE yield_arg, VALUE parser, int argc, VALUE* argv, VALUE block_arg) {
  yyparse(parser);
  return rb_ivar_get(parser, rb_intern("@result"));
}

VALUE GraphQL_Language_CParser_parse(VALUE self, VALUE query_string, VALUE trace) {
  VALUE opts = rb_hash_new();
  rb_hash_aset(opts, ID2SYM(rb_intern("query_string")), query_string);
  VALUE argv[] = {opts};
  VALUE tokens = rb_block_call_kw(trace, rb_intern("lex"), 1, argv, call_tokenize, query_string, RB_PASS_KEYWORDS);

  VALUE parser = rb_class_new(self);
  rb_ivar_set(parser, rb_intern("@query_string"), query_string);
  rb_ivar_set(parser, rb_intern("@tokens"), tokens);
  rb_ivar_set(parser, rb_intern("@next_token_index"), INT2FIX(0));
  rb_ivar_set(parser, rb_intern("@result"), Qnil);
  return rb_block_call_kw(trace, rb_intern("parse"), 1, argv, call_yyparse, parser, RB_PASS_KEYWORDS);
}

void Init_graphql_c_parser_ext() {
  VALUE GraphQL = rb_define_module("GraphQL");
  VALUE Language = rb_define_module_under(GraphQL, "Language");
  VALUE CLexer = rb_define_module_under(Language, "CLexer");
  rb_define_singleton_method(CLexer, "tokenize", GraphQL_Language_CLexer_tokenize, 1);
  setup_static_token_variables();

  VALUE CParser = rb_define_class_under(Language, "CParser", rb_cObject);
  rb_define_singleton_method(CParser, "parse", GraphQL_Language_CParser_parse, 2);
  initialize_node_class_variables();
}
