#ifndef Graphql_lexer_h
#define Graphql_lexer_h
#include <ruby.h>
VALUE tokenize(VALUE query_rbstr);
void setup_static_token_variables();
#endif
