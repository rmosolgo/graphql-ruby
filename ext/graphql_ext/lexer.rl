%%{
  machine graphql_c_lexer;


  IDENTIFIER =    [_A-Za-z][_0-9A-Za-z]*;
  NEWLINE =       [\c\r\n];
  BLANK   =       [, \t]+;
  COMMENT =       '#' [^\n\r]*;
  INT =           '-'? ('0'|[1-9][0-9]*);
  FLOAT_DECIMAL = '.'[0-9]+;
  FLOAT_EXP =     ('e' | 'E')?('+' | '-')?[0-9]+;
  FLOAT =         INT FLOAT_DECIMAL? FLOAT_EXP?;
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
  QUOTE =         '"';
  BACKSLASH = '\\';
  # Could limit to hex here, but “bad unicode escape” on 0XXF is probably a
  # more helpful error than “unknown char”
  UNICODE_DIGIT = [0-9A-Za-z];
  FOUR_DIGIT_UNICODE = UNICODE_DIGIT{4};
  N_DIGIT_UNICODE = LCURLY UNICODE_DIGIT{4,} RCURLY;
  UNICODE_ESCAPE = '\\u' (FOUR_DIGIT_UNICODE | N_DIGIT_UNICODE);
  # https://graphql.github.io/graphql-spec/June2018/#sec-String-Value
  STRING_ESCAPE = '\\' [\\/bfnrt];
  BLOCK_QUOTE =   '"""';
  ESCAPED_BLOCK_QUOTE = '\\"""';
  BLOCK_STRING_CHAR = (ESCAPED_BLOCK_QUOTE | ^QUOTE | QUOTE{1,2} ^QUOTE);
  ESCAPED_QUOTE = '\\"';
  STRING_CHAR =   ((ESCAPED_QUOTE | ^QUOTE) - BACKSLASH) | UNICODE_ESCAPE | STRING_ESCAPE;
  VAR_SIGN =      '$';
  DIR_SIGN =      '@';
  ELLIPSIS =      '...';
  EQUALS =        '=';
  BANG =          '!';
  PIPE =          '|';
  AMP =           '&';

  QUOTED_STRING = QUOTE STRING_CHAR* QUOTE;
  BLOCK_STRING = BLOCK_QUOTE BLOCK_STRING_CHAR* QUOTE{0,2} BLOCK_QUOTE;
  # catch-all for anything else. must be at the bottom for precedence.
  UNKNOWN_CHAR =         /./;

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
    QUOTED_STRING => { emit_string(ts, te, meta, 0); };
    BLOCK_STRING  => { emit_string(ts, te, meta, 1); };
    VAR_SIGN      => { emit(VAR_SIGN, ts, te, meta); };
    DIR_SIGN      => { emit(DIR_SIGN, ts, te, meta); };
    ELLIPSIS      => { emit(ELLIPSIS, ts, te, meta); };
    EQUALS        => { emit(EQUALS, ts, te, meta); };
    BANG          => { emit(BANG, ts, te, meta); };
    PIPE          => { emit(PIPE, ts, te, meta); };
    AMP           => { emit(AMP, ts, te, meta); };
    IDENTIFIER    => { emit(IDENTIFIER, ts, te, meta); };
    COMMENT       => { record_comment(ts, te, meta); };

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
  NEWLINE,
  BLANK,
  UNKNOWN_CHAR
} TokenType;

typedef struct Meta {
  int line;
  int col;
  char *query_cstr;
} Meta;

void emit(TokenType tt, char *ts, char *te, Meta *meta) {
  char *content;

  switch(tt) {
    case ON: content = "on"; break;
    case FRAGMENT: content = "fragment"; break;
    case TRUE_LITERAL: content = "true"; break;
    case FALSE_LITERAL: content = "false"; break;
    case NULL_LITERAL: content = "null"; break;
    case QUERY: content = "query"; break;
    case MUTATION: content = "mutation"; break;
    case SUBSCRIPTION: content = "subscription"; break;
    case REPEATABLE: content = "repeatable"; break;
    case RCURLY: content = "}"; break;
    case LCURLY: content = "{"; break;
    case RPAREN: content = ")"; break;
    case LPAREN: content = "("; break;
    case RBRACKET: content = "]"; break;
    case LBRACKET: content = "["; break;
    case COLON: content = ":"; break;
    case VAR_SIGN: content = "$"; break;
    case DIR_SIGN: content = "@"; break;
    case ELLIPSIS: content = "..."; break;
    case EQUALS: content = "="; break;
    case BANG: content = "!"; break;
    case PIPE: content = "|"; break;
    case AMP: content = "&"; break;
    default: content = "read from query_str";
  }

}

void emit_string(char *ts, char *te, Meta *meta, int is_block) {

}

void record_comment(char *ts, char *te, Meta *meta) {

}


void push_token(VALUE tokens, char *ts, char *te) {
  VALUE rb_token_ary = rb_ary_new2(4);
  // rb_ary_aref(0, rb_str_new_cstr(token_content))
  rb_ary_push(tokens, rb_token_ary);
}

int tokenize(VALUE query_rbstr) {
  int cs, act = 0;
  char *p = rb_string_value_cstr(query_rbstr);
  char *pe = p + strlen(p) + 1;
  char *ts, *te;
  VALUE tokens = rb_ary_new();

  struct Meta meta_s = {0, 0, p};
  Meta *meta = &meta_s;

  %% write init;
  %% write exec;
  return 0;
}
