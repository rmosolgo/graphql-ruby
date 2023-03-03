%%{
  machine graphql_c_lexer;

  IDENTIFIER =    [_A-Za-z][_0-9A-Za-z]*;
  NEWLINE =       [\c\r\n];
  BLANK   =       [, \t]+;
  COMMENT =       '#' [^\n\r]*;
  INT =           '-'? ('0'|[1-9][0-9]*);
  FLOAT =         INT ('.'[0-9]+)? (('e' | 'E')?('+' | '-')?[0-9]+)?;
  ON =            'on';
  FRAGMENT =      'fragment';
  TRUE_LITERAL =  'true';
  FALSE_LITERAL = 'false';
  NULL_LITERAL =  'null';
  QUERY =         'query';
  MUTATION =      'mutation';
  SUBSCRIPTION =  'subscription';
  SCHEMA =        'schema';
  SCALAR =        'scalar';
  TYPE =          'type';
  EXTEND =        'extend';
  IMPLEMENTS =    'implements';
  INTERFACE =     'interface';
  UNION =         'union';
  ENUM =          'enum';
  INPUT =         'input';
  DIRECTIVE =     'directive';
  REPEATABLE =    'repeatable';
  LCURLY =        '{';
  RCURLY =        '}';
  LPAREN =        '(';
  RPAREN =        ')';
  LBRACKET =      '[';
  RBRACKET =      ']';
  COLON =         ':';
  # Could limit to hex here, but “bad unicode escape” on 0XXF is probably a
  # more helpful error than “unknown char”
  UNICODE_ESCAPE = "\\u" ([0-9A-Za-z]{4} | LCURLY [0-9A-Za-z]{4,} RCURLY);
  VAR_SIGN =      '$';
  DIR_SIGN =      '@';
  ELLIPSIS =      '...';
  EQUALS =        '=';
  BANG =          '!';
  PIPE =          '|';
  AMP =           '&';

  QUOTED_STRING = ('"' ((('\\"' | ^'"') - "\\") | UNICODE_ESCAPE | '\\' [\\/bfnrt])* '"');
  # catch-all for anything else. must be at the bottom for precedence.
  UNKNOWN_CHAR =         /./;

  BLOCK_STRING = ('"""' ('\\"""' | ^'"' | '"'{1,2} ^'"')* '"'{0,2} '"""');

  main := |*
    INT           => { emit(INT, ts, te, meta); };
    FLOAT         => { emit(FLOAT, ts, te, meta); };
    ON            => { emit(ON, ts, te, meta); };
    FRAGMENT      => { emit(FRAGMENT, ts, te, meta); };
    TRUE_LITERAL  => { emit(TRUE_LITERAL, ts, te, meta); };
    FALSE_LITERAL => { emit(FALSE_LITERAL, ts, te, meta); };
    NULL_LITERAL  => { emit(NULL_LITERAL, ts, te, meta); };
    QUERY         => { emit(QUERY, ts, te, meta); };
    MUTATION      => { emit(MUTATION, ts, te, meta); };
    SUBSCRIPTION  => { emit(SUBSCRIPTION, ts, te, meta); };
    SCHEMA        => { emit(SCHEMA, ts, te, meta); };
    SCALAR        => { emit(SCALAR, ts, te, meta); };
    TYPE          => { emit(TYPE, ts, te, meta); };
    EXTEND        => { emit(EXTEND, ts, te, meta); };
    IMPLEMENTS    => { emit(IMPLEMENTS, ts, te, meta); };
    INTERFACE     => { emit(INTERFACE, ts, te, meta); };
    UNION         => { emit(UNION, ts, te, meta); };
    ENUM          => { emit(ENUM, ts, te, meta); };
    INPUT         => { emit(INPUT, ts, te, meta); };
    DIRECTIVE     => { emit(DIRECTIVE, ts, te, meta); };
    REPEATABLE    => { emit(REPEATABLE, ts, te, meta); };
    RCURLY        => { emit(RCURLY, ts, te, meta); };
    LCURLY        => { emit(LCURLY, ts, te, meta); };
    RPAREN        => { emit(RPAREN, ts, te, meta); };
    LPAREN        => { emit(LPAREN, ts, te, meta); };
    RBRACKET      => { emit(RBRACKET, ts, te, meta); };
    LBRACKET      => { emit(LBRACKET, ts, te, meta); };
    COLON         => { emit(COLON, ts, te, meta); };
    BLOCK_STRING  => { emit(BLOCK_STRING, ts, te, meta); };
    QUOTED_STRING => { emit(QUOTED_STRING, ts, te, meta); };
    VAR_SIGN      => { emit(VAR_SIGN, ts, te, meta); };
    DIR_SIGN      => { emit(DIR_SIGN, ts, te, meta); };
    ELLIPSIS      => { emit(ELLIPSIS, ts, te, meta); };
    EQUALS        => { emit(EQUALS, ts, te, meta); };
    BANG          => { emit(BANG, ts, te, meta); };
    PIPE          => { emit(PIPE, ts, te, meta); };
    AMP           => { emit(AMP, ts, te, meta); };
    IDENTIFIER    => { emit(IDENTIFIER, ts, te, meta); };
    COMMENT       => { emit(COMMENT, ts, te, meta); };
    NEWLINE => {
      meta->line += 1;
      meta->col = 1;
    };

    BLANK   => { meta->col += te - ts; };

    UNKNOWN_CHAR => { emit(UNKNOWN_CHAR, ts, te, meta); };
  *|;
}%%

%% write data;

#include <ruby.h>

#define INIT_STATIC_TOKEN_VARIABLE(token_name) \
  static VALUE GraphQLTokenString##token_name;

INIT_STATIC_TOKEN_VARIABLE(ON)
INIT_STATIC_TOKEN_VARIABLE(FRAGMENT)
INIT_STATIC_TOKEN_VARIABLE(QUERY)
INIT_STATIC_TOKEN_VARIABLE(MUTATION)
INIT_STATIC_TOKEN_VARIABLE(SUBSCRIPTION)
INIT_STATIC_TOKEN_VARIABLE(REPEATABLE)
INIT_STATIC_TOKEN_VARIABLE(RCURLY)
INIT_STATIC_TOKEN_VARIABLE(LCURLY)
INIT_STATIC_TOKEN_VARIABLE(RBRACKET)
INIT_STATIC_TOKEN_VARIABLE(LBRACKET)
INIT_STATIC_TOKEN_VARIABLE(RPAREN)
INIT_STATIC_TOKEN_VARIABLE(LPAREN)
INIT_STATIC_TOKEN_VARIABLE(COLON)
INIT_STATIC_TOKEN_VARIABLE(VAR_SIGN)
INIT_STATIC_TOKEN_VARIABLE(DIR_SIGN)
INIT_STATIC_TOKEN_VARIABLE(ELLIPSIS)
INIT_STATIC_TOKEN_VARIABLE(EQUALS)
INIT_STATIC_TOKEN_VARIABLE(BANG)
INIT_STATIC_TOKEN_VARIABLE(PIPE)
INIT_STATIC_TOKEN_VARIABLE(AMP)
INIT_STATIC_TOKEN_VARIABLE(SCHEMA)
INIT_STATIC_TOKEN_VARIABLE(SCALAR)
INIT_STATIC_TOKEN_VARIABLE(TYPE)
INIT_STATIC_TOKEN_VARIABLE(EXTEND)
INIT_STATIC_TOKEN_VARIABLE(IMPLEMENTS)
INIT_STATIC_TOKEN_VARIABLE(INTERFACE)
INIT_STATIC_TOKEN_VARIABLE(UNION)
INIT_STATIC_TOKEN_VARIABLE(ENUM)
INIT_STATIC_TOKEN_VARIABLE(DIRECTIVE)
INIT_STATIC_TOKEN_VARIABLE(INPUT)

typedef enum TokenType {
  INT,
  FLOAT,
  ON,
  FRAGMENT,
  TRUE_LITERAL,
  FALSE_LITERAL,
  NULL_LITERAL,
  QUERY,
  MUTATION,
  SUBSCRIPTION,
  SCHEMA,
  SCALAR,
  TYPE,
  EXTEND,
  IMPLEMENTS,
  INTERFACE,
  UNION,
  ENUM,
  INPUT,
  DIRECTIVE,
  REPEATABLE,
  RCURLY,
  LCURLY,
  RPAREN,
  LPAREN,
  RBRACKET,
  LBRACKET,
  COLON,
  QUOTED_STRING,
  BLOCK_STRING,
  VAR_SIGN,
  DIR_SIGN,
  ELLIPSIS,
  EQUALS,
  BANG,
  PIPE,
  AMP,
  IDENTIFIER,
  COMMENT,
  UNKNOWN_CHAR
} TokenType;

typedef struct Meta {
  int line;
  int col;
  char *query_cstr;
  char *pe;
  VALUE tokens;
  VALUE previous_token;
} Meta;

#define STATIC_VALUE_TOKEN(token_type, content_str) \
  case token_type: \
  token_sym = ID2SYM(rb_intern(#token_type)); \
  token_content = GraphQLTokenString##token_type; \
  break;

#define DYNAMIC_VALUE_TOKEN(token_type) \
  case token_type: \
  token_sym = ID2SYM(rb_intern(#token_type)); \
  token_content = rb_utf8_str_new(ts, te - ts); \
  break;

void emit(TokenType tt, char *ts, char *te, Meta *meta) {
  int quotes_length = 0; // set by string tokens below
  int line_incr = 0;
  VALUE token_sym = Qnil;
  VALUE token_content = Qnil;

  switch(tt) {
    STATIC_VALUE_TOKEN(ON, "on")
    STATIC_VALUE_TOKEN(FRAGMENT, "fragment")
    STATIC_VALUE_TOKEN(QUERY, "query")
    STATIC_VALUE_TOKEN(MUTATION, "mutation")
    STATIC_VALUE_TOKEN(SUBSCRIPTION, "subscription")
    STATIC_VALUE_TOKEN(REPEATABLE, "repeatable")
    STATIC_VALUE_TOKEN(RCURLY, "}")
    STATIC_VALUE_TOKEN(LCURLY, "{")
    STATIC_VALUE_TOKEN(RBRACKET, "]")
    STATIC_VALUE_TOKEN(LBRACKET, "[")
    STATIC_VALUE_TOKEN(RPAREN, ")")
    STATIC_VALUE_TOKEN(LPAREN, "(")
    STATIC_VALUE_TOKEN(COLON, ":")
    STATIC_VALUE_TOKEN(VAR_SIGN, "$")
    STATIC_VALUE_TOKEN(DIR_SIGN, "@")
    STATIC_VALUE_TOKEN(ELLIPSIS, "...")
    STATIC_VALUE_TOKEN(EQUALS, "=")
    STATIC_VALUE_TOKEN(BANG, "!")
    STATIC_VALUE_TOKEN(PIPE, "|")
    STATIC_VALUE_TOKEN(AMP, "&")
    STATIC_VALUE_TOKEN(SCHEMA, "schema")
    STATIC_VALUE_TOKEN(SCALAR, "scalar")
    STATIC_VALUE_TOKEN(TYPE, "type")
    STATIC_VALUE_TOKEN(EXTEND, "extend")
    STATIC_VALUE_TOKEN(IMPLEMENTS, "implements")
    STATIC_VALUE_TOKEN(INTERFACE, "interface")
    STATIC_VALUE_TOKEN(UNION, "union")
    STATIC_VALUE_TOKEN(ENUM, "enum")
    STATIC_VALUE_TOKEN(DIRECTIVE, "directive")
    STATIC_VALUE_TOKEN(INPUT, "input")
    // For these, the enum name doesn't match the symbol name:
    case TRUE_LITERAL:
      token_sym = ID2SYM(rb_intern("TRUE"));
      token_content = rb_str_new_cstr("true");
      break;
    case FALSE_LITERAL:
      token_sym = ID2SYM(rb_intern("FALSE"));
      token_content = rb_str_new_cstr("false");
      break;
    case NULL_LITERAL:
      token_sym = ID2SYM(rb_intern("NULL"));
      token_content = rb_str_new_cstr("null");
      break;
    DYNAMIC_VALUE_TOKEN(IDENTIFIER)
    DYNAMIC_VALUE_TOKEN(INT)
    DYNAMIC_VALUE_TOKEN(FLOAT)
    DYNAMIC_VALUE_TOKEN(COMMENT)
    case UNKNOWN_CHAR:
      if (ts[0] == '\0') {
        return;
      } else {
        token_content = rb_utf8_str_new(ts, te - ts);
        token_sym = ID2SYM(rb_intern("UNKNOWN_CHAR"));
        break;
      }
    case QUOTED_STRING:
      quotes_length = 1;
      token_content = rb_utf8_str_new(ts + quotes_length, (te - ts - (2 * quotes_length)));
      token_sym = ID2SYM(rb_intern("STRING"));
      break;
    case BLOCK_STRING:
      token_sym = ID2SYM(rb_intern("STRING"));
      quotes_length = 3;
      token_content = rb_utf8_str_new(ts + quotes_length, (te - ts - (2 * quotes_length)));
      line_incr = FIX2INT(rb_funcall(token_content, rb_intern("count"), 1, rb_str_new_cstr("\n")));
      break;
  }

  if (token_sym != Qnil) {
    if (tt == BLOCK_STRING || tt == QUOTED_STRING) {
      VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
      VALUE mGraphQLLanguage = rb_const_get_at(mGraphQL, rb_intern("Language"));
      VALUE mGraphQLLanguageLexer = rb_const_get_at(mGraphQLLanguage, rb_intern("Lexer"));
      VALUE valid_string_pattern = rb_const_get_at(mGraphQLLanguageLexer, rb_intern("VALID_STRING"));
      if (tt == BLOCK_STRING) {
        VALUE mGraphQLLanguageBlockString = rb_const_get_at(mGraphQLLanguage, rb_intern("BlockString"));
        token_content = rb_funcall(mGraphQLLanguageBlockString, rb_intern("trim_whitespace"), 1, token_content);
      }

      if (
        RB_TEST(rb_funcall(token_content, rb_intern("valid_encoding?"), 0)) &&
          RB_TEST(rb_funcall(token_content, rb_intern("match?"), 1, valid_string_pattern))
      ) {
        rb_funcall(mGraphQLLanguageLexer, rb_intern("replace_escaped_characters_in_place"), 1, token_content);
        if (!RB_TEST(rb_funcall(token_content, rb_intern("valid_encoding?"), 0))) {
          token_sym = ID2SYM(rb_intern("BAD_UNICODE_ESCAPE"));
        }


      } else {
        token_sym = ID2SYM(rb_intern("BAD_UNICODE_ESCAPE"));
      }
    }

    VALUE token_data[5] = {
      token_sym,
      rb_int2inum(meta->line),
      rb_int2inum(meta->col),
      token_content,
      meta->previous_token,
    };
    VALUE token = rb_ary_new_from_values(5, token_data);
    // COMMENTs are retained as `previous_token` but aren't pushed to the normal token list
    if (tt != COMMENT) {
      rb_ary_push(meta->tokens, token);
    }
    meta->previous_token = token;
  }
  // Bump the column counter for the next token
  meta->col += te - ts;
  meta->line += line_incr;
}

VALUE tokenize(VALUE query_rbstr) {
  int cs = 0;
  int act = 0;
  char *p = StringValueCStr(query_rbstr);
  char *pe = p + strlen(p);
  char *eof = pe;
  char *ts = 0;
  char *te = 0;
  VALUE tokens = rb_ary_new();
  struct Meta meta_s = {1, 1, p, pe, tokens, Qnil};
  Meta *meta = &meta_s;

  %% write init;
  %% write exec;

  return tokens;
}


#define SETUP_STATIC_TOKEN_VARIABLE(token_name, token_content) \
  GraphQLTokenString##token_name = rb_str_new_cstr(token_content); \
  rb_funcall(GraphQLTokenString##token_name, rb_intern("-@"), 0); \
  rb_global_variable(&GraphQLTokenString##token_name); \

void setup_static_token_variables() {
  SETUP_STATIC_TOKEN_VARIABLE(ON, "on")
  SETUP_STATIC_TOKEN_VARIABLE(FRAGMENT, "fragment")
  SETUP_STATIC_TOKEN_VARIABLE(QUERY, "query")
  SETUP_STATIC_TOKEN_VARIABLE(MUTATION, "mutation")
  SETUP_STATIC_TOKEN_VARIABLE(SUBSCRIPTION, "subscription")
  SETUP_STATIC_TOKEN_VARIABLE(REPEATABLE, "repeatable")
  SETUP_STATIC_TOKEN_VARIABLE(RCURLY, "}")
  SETUP_STATIC_TOKEN_VARIABLE(LCURLY, "{")
  SETUP_STATIC_TOKEN_VARIABLE(RBRACKET, "]")
  SETUP_STATIC_TOKEN_VARIABLE(LBRACKET, "[")
  SETUP_STATIC_TOKEN_VARIABLE(RPAREN, ")")
  SETUP_STATIC_TOKEN_VARIABLE(LPAREN, "(")
  SETUP_STATIC_TOKEN_VARIABLE(COLON, ":")
  SETUP_STATIC_TOKEN_VARIABLE(VAR_SIGN, "$")
  SETUP_STATIC_TOKEN_VARIABLE(DIR_SIGN, "@")
  SETUP_STATIC_TOKEN_VARIABLE(ELLIPSIS, "...")
  SETUP_STATIC_TOKEN_VARIABLE(EQUALS, "=")
  SETUP_STATIC_TOKEN_VARIABLE(BANG, "!")
  SETUP_STATIC_TOKEN_VARIABLE(PIPE, "|")
  SETUP_STATIC_TOKEN_VARIABLE(AMP, "&")
  SETUP_STATIC_TOKEN_VARIABLE(SCHEMA, "schema")
  SETUP_STATIC_TOKEN_VARIABLE(SCALAR, "scalar")
  SETUP_STATIC_TOKEN_VARIABLE(TYPE, "type")
  SETUP_STATIC_TOKEN_VARIABLE(EXTEND, "extend")
  SETUP_STATIC_TOKEN_VARIABLE(IMPLEMENTS, "implements")
  SETUP_STATIC_TOKEN_VARIABLE(INTERFACE, "interface")
  SETUP_STATIC_TOKEN_VARIABLE(UNION, "union")
  SETUP_STATIC_TOKEN_VARIABLE(ENUM, "enum")
  SETUP_STATIC_TOKEN_VARIABLE(DIRECTIVE, "directive")
  SETUP_STATIC_TOKEN_VARIABLE(INPUT, "input")
}
