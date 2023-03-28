/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 2

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 5 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"

// C Declarations
#include <ruby.h>
#define YYSTYPE VALUE
int yylex(YYSTYPE *, VALUE);
void yyerror(VALUE, const char*);

static VALUE GraphQL_Language_Nodes_NONE;
static VALUE r_string_query;
#define SETUP_NODE_CLASS_VARIABLE(node_class_name) static VALUE GraphQL_Language_Nodes_##node_class_name;

SETUP_NODE_CLASS_VARIABLE(Argument)
SETUP_NODE_CLASS_VARIABLE(Directive)
SETUP_NODE_CLASS_VARIABLE(Document)
SETUP_NODE_CLASS_VARIABLE(Enum)
SETUP_NODE_CLASS_VARIABLE(Field)
SETUP_NODE_CLASS_VARIABLE(FragmentDefinition)
SETUP_NODE_CLASS_VARIABLE(FragmentSpread)
SETUP_NODE_CLASS_VARIABLE(InlineFragment)
SETUP_NODE_CLASS_VARIABLE(InputObject)
SETUP_NODE_CLASS_VARIABLE(ListType)
SETUP_NODE_CLASS_VARIABLE(NonNullType)
SETUP_NODE_CLASS_VARIABLE(NullValue)
SETUP_NODE_CLASS_VARIABLE(OperationDefinition)
SETUP_NODE_CLASS_VARIABLE(TypeName)
SETUP_NODE_CLASS_VARIABLE(VariableDefinition)
SETUP_NODE_CLASS_VARIABLE(VariableIdentifier)

SETUP_NODE_CLASS_VARIABLE(ScalarTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(ObjectTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(InterfaceTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(UnionTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(EnumTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(InputObjectTypeDefinition)
SETUP_NODE_CLASS_VARIABLE(EnumValueDefinition)
SETUP_NODE_CLASS_VARIABLE(DirectiveDefinition)
SETUP_NODE_CLASS_VARIABLE(DirectiveLocation)
SETUP_NODE_CLASS_VARIABLE(FieldDefinition)
SETUP_NODE_CLASS_VARIABLE(InputValueDefinition)
SETUP_NODE_CLASS_VARIABLE(SchemaDefinition)

SETUP_NODE_CLASS_VARIABLE(ScalarTypeExtension)
SETUP_NODE_CLASS_VARIABLE(ObjectTypeExtension)
SETUP_NODE_CLASS_VARIABLE(InterfaceTypeExtension)
SETUP_NODE_CLASS_VARIABLE(UnionTypeExtension)
SETUP_NODE_CLASS_VARIABLE(EnumTypeExtension)
SETUP_NODE_CLASS_VARIABLE(InputObjectTypeExtension)
SETUP_NODE_CLASS_VARIABLE(SchemaExtension)

#line 121 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif


/* Debug traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif
#if YYDEBUG
extern int yydebug;
#endif

/* Token kinds.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
  enum yytokentype
  {
    YYEMPTY = -2,
    YYEOF = 0,                     /* "end of file"  */
    YYerror = 256,                 /* error  */
    YYUNDEF = 257,                 /* "invalid token"  */
    AMP = 200,                     /* AMP  */
    BANG = 201,                    /* BANG  */
    COLON = 202,                   /* COLON  */
    DIRECTIVE = 203,               /* DIRECTIVE  */
    DIR_SIGN = 204,                /* DIR_SIGN  */
    ENUM = 205,                    /* ENUM  */
    ELLIPSIS = 206,                /* ELLIPSIS  */
    EQUALS = 207,                  /* EQUALS  */
    EXTEND = 208,                  /* EXTEND  */
    FALSE_LITERAL = 209,           /* FALSE_LITERAL  */
    FLOAT = 210,                   /* FLOAT  */
    FRAGMENT = 211,                /* FRAGMENT  */
    IDENTIFIER = 212,              /* IDENTIFIER  */
    INPUT = 213,                   /* INPUT  */
    IMPLEMENTS = 214,              /* IMPLEMENTS  */
    INT = 215,                     /* INT  */
    INTERFACE = 216,               /* INTERFACE  */
    LBRACKET = 217,                /* LBRACKET  */
    LCURLY = 218,                  /* LCURLY  */
    LPAREN = 219,                  /* LPAREN  */
    MUTATION = 220,                /* MUTATION  */
    NULL_LITERAL = 221,            /* NULL_LITERAL  */
    ON = 222,                      /* ON  */
    PIPE = 223,                    /* PIPE  */
    QUERY = 224,                   /* QUERY  */
    RBRACKET = 225,                /* RBRACKET  */
    RCURLY = 226,                  /* RCURLY  */
    REPEATABLE = 227,              /* REPEATABLE  */
    RPAREN = 228,                  /* RPAREN  */
    SCALAR = 229,                  /* SCALAR  */
    SCHEMA = 230,                  /* SCHEMA  */
    STRING = 231,                  /* STRING  */
    SUBSCRIPTION = 232,            /* SUBSCRIPTION  */
    TRUE_LITERAL = 233,            /* TRUE_LITERAL  */
    TYPE_LITERAL = 234,            /* TYPE_LITERAL  */
    UNION = 235,                   /* UNION  */
    VAR_SIGN = 236                 /* VAR_SIGN  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
#define AMP 200
#define BANG 201
#define COLON 202
#define DIRECTIVE 203
#define DIR_SIGN 204
#define ENUM 205
#define ELLIPSIS 206
#define EQUALS 207
#define EXTEND 208
#define FALSE_LITERAL 209
#define FLOAT 210
#define FRAGMENT 211
#define IDENTIFIER 212
#define INPUT 213
#define IMPLEMENTS 214
#define INT 215
#define INTERFACE 216
#define LBRACKET 217
#define LCURLY 218
#define LPAREN 219
#define MUTATION 220
#define NULL_LITERAL 221
#define ON 222
#define PIPE 223
#define QUERY 224
#define RBRACKET 225
#define RCURLY 226
#define REPEATABLE 227
#define RPAREN 228
#define SCALAR 229
#define SCHEMA 230
#define STRING 231
#define SUBSCRIPTION 232
#define TRUE_LITERAL 233
#define TYPE_LITERAL 234
#define UNION 235
#define VAR_SIGN 236

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif




int yyparse (VALUE parser);



/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_AMP = 3,                        /* AMP  */
  YYSYMBOL_BANG = 4,                       /* BANG  */
  YYSYMBOL_COLON = 5,                      /* COLON  */
  YYSYMBOL_DIRECTIVE = 6,                  /* DIRECTIVE  */
  YYSYMBOL_DIR_SIGN = 7,                   /* DIR_SIGN  */
  YYSYMBOL_ENUM = 8,                       /* ENUM  */
  YYSYMBOL_ELLIPSIS = 9,                   /* ELLIPSIS  */
  YYSYMBOL_EQUALS = 10,                    /* EQUALS  */
  YYSYMBOL_EXTEND = 11,                    /* EXTEND  */
  YYSYMBOL_FALSE_LITERAL = 12,             /* FALSE_LITERAL  */
  YYSYMBOL_FLOAT = 13,                     /* FLOAT  */
  YYSYMBOL_FRAGMENT = 14,                  /* FRAGMENT  */
  YYSYMBOL_IDENTIFIER = 15,                /* IDENTIFIER  */
  YYSYMBOL_INPUT = 16,                     /* INPUT  */
  YYSYMBOL_IMPLEMENTS = 17,                /* IMPLEMENTS  */
  YYSYMBOL_INT = 18,                       /* INT  */
  YYSYMBOL_INTERFACE = 19,                 /* INTERFACE  */
  YYSYMBOL_LBRACKET = 20,                  /* LBRACKET  */
  YYSYMBOL_LCURLY = 21,                    /* LCURLY  */
  YYSYMBOL_LPAREN = 22,                    /* LPAREN  */
  YYSYMBOL_MUTATION = 23,                  /* MUTATION  */
  YYSYMBOL_NULL_LITERAL = 24,              /* NULL_LITERAL  */
  YYSYMBOL_ON = 25,                        /* ON  */
  YYSYMBOL_PIPE = 26,                      /* PIPE  */
  YYSYMBOL_QUERY = 27,                     /* QUERY  */
  YYSYMBOL_RBRACKET = 28,                  /* RBRACKET  */
  YYSYMBOL_RCURLY = 29,                    /* RCURLY  */
  YYSYMBOL_REPEATABLE = 30,                /* REPEATABLE  */
  YYSYMBOL_RPAREN = 31,                    /* RPAREN  */
  YYSYMBOL_SCALAR = 32,                    /* SCALAR  */
  YYSYMBOL_SCHEMA = 33,                    /* SCHEMA  */
  YYSYMBOL_STRING = 34,                    /* STRING  */
  YYSYMBOL_SUBSCRIPTION = 35,              /* SUBSCRIPTION  */
  YYSYMBOL_TRUE_LITERAL = 36,              /* TRUE_LITERAL  */
  YYSYMBOL_TYPE_LITERAL = 37,              /* TYPE_LITERAL  */
  YYSYMBOL_UNION = 38,                     /* UNION  */
  YYSYMBOL_VAR_SIGN = 39,                  /* VAR_SIGN  */
  YYSYMBOL_YYACCEPT = 40,                  /* $accept  */
  YYSYMBOL_start = 41,                     /* start  */
  YYSYMBOL_document = 42,                  /* document  */
  YYSYMBOL_definitions_list = 43,          /* definitions_list  */
  YYSYMBOL_definition = 44,                /* definition  */
  YYSYMBOL_executable_definition = 45,     /* executable_definition  */
  YYSYMBOL_operation_definition = 46,      /* operation_definition  */
  YYSYMBOL_operation_type = 47,            /* operation_type  */
  YYSYMBOL_operation_name_opt = 48,        /* operation_name_opt  */
  YYSYMBOL_variable_definitions_opt = 49,  /* variable_definitions_opt  */
  YYSYMBOL_variable_definitions_list = 50, /* variable_definitions_list  */
  YYSYMBOL_variable_definition = 51,       /* variable_definition  */
  YYSYMBOL_default_value_opt = 52,         /* default_value_opt  */
  YYSYMBOL_selection_list = 53,            /* selection_list  */
  YYSYMBOL_selection = 54,                 /* selection  */
  YYSYMBOL_selection_set = 55,             /* selection_set  */
  YYSYMBOL_selection_set_opt = 56,         /* selection_set_opt  */
  YYSYMBOL_field = 57,                     /* field  */
  YYSYMBOL_arguments_opt = 58,             /* arguments_opt  */
  YYSYMBOL_arguments_list = 59,            /* arguments_list  */
  YYSYMBOL_argument = 60,                  /* argument  */
  YYSYMBOL_literal_value = 61,             /* literal_value  */
  YYSYMBOL_input_value = 62,               /* input_value  */
  YYSYMBOL_null_value = 63,                /* null_value  */
  YYSYMBOL_variable = 64,                  /* variable  */
  YYSYMBOL_list_value = 65,                /* list_value  */
  YYSYMBOL_list_value_list = 66,           /* list_value_list  */
  YYSYMBOL_enum_name = 67,                 /* enum_name  */
  YYSYMBOL_enum_value = 68,                /* enum_value  */
  YYSYMBOL_object_value = 69,              /* object_value  */
  YYSYMBOL_object_value_list_opt = 70,     /* object_value_list_opt  */
  YYSYMBOL_object_value_list = 71,         /* object_value_list  */
  YYSYMBOL_object_value_field = 72,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 73,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list_opt = 74, /* object_literal_value_list_opt  */
  YYSYMBOL_object_literal_value_list = 75, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 76, /* object_literal_value_field  */
  YYSYMBOL_directives_list_opt = 77,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 78,           /* directives_list  */
  YYSYMBOL_directive = 79,                 /* directive  */
  YYSYMBOL_name = 80,                      /* name  */
  YYSYMBOL_schema_keyword = 81,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 82,           /* name_without_on  */
  YYSYMBOL_fragment_spread = 83,           /* fragment_spread  */
  YYSYMBOL_inline_fragment = 84,           /* inline_fragment  */
  YYSYMBOL_fragment_definition = 85,       /* fragment_definition  */
  YYSYMBOL_fragment_name_opt = 86,         /* fragment_name_opt  */
  YYSYMBOL_type = 87,                      /* type  */
  YYSYMBOL_nullable_type = 88,             /* nullable_type  */
  YYSYMBOL_type_system_definition = 89,    /* type_system_definition  */
  YYSYMBOL_schema_definition = 90,         /* schema_definition  */
  YYSYMBOL_operation_type_definition_list = 91, /* operation_type_definition_list  */
  YYSYMBOL_operation_type_definition = 92, /* operation_type_definition  */
  YYSYMBOL_type_definition = 93,           /* type_definition  */
  YYSYMBOL_description = 94,               /* description  */
  YYSYMBOL_description_opt = 95,           /* description_opt  */
  YYSYMBOL_scalar_type_definition = 96,    /* scalar_type_definition  */
  YYSYMBOL_object_type_definition = 97,    /* object_type_definition  */
  YYSYMBOL_implements_opt = 98,            /* implements_opt  */
  YYSYMBOL_interfaces_list = 99,           /* interfaces_list  */
  YYSYMBOL_legacy_interfaces_list = 100,   /* legacy_interfaces_list  */
  YYSYMBOL_input_value_definition = 101,   /* input_value_definition  */
  YYSYMBOL_input_value_definition_list = 102, /* input_value_definition_list  */
  YYSYMBOL_arguments_definitions_opt = 103, /* arguments_definitions_opt  */
  YYSYMBOL_field_definition = 104,         /* field_definition  */
  YYSYMBOL_field_definition_list_opt = 105, /* field_definition_list_opt  */
  YYSYMBOL_field_definition_list = 106,    /* field_definition_list  */
  YYSYMBOL_interface_type_definition = 107, /* interface_type_definition  */
  YYSYMBOL_union_members = 108,            /* union_members  */
  YYSYMBOL_union_type_definition = 109,    /* union_type_definition  */
  YYSYMBOL_enum_type_definition = 110,     /* enum_type_definition  */
  YYSYMBOL_enum_value_definition = 111,    /* enum_value_definition  */
  YYSYMBOL_enum_value_definitions = 112,   /* enum_value_definitions  */
  YYSYMBOL_input_object_type_definition = 113, /* input_object_type_definition  */
  YYSYMBOL_directive_definition = 114,     /* directive_definition  */
  YYSYMBOL_directive_repeatable_opt = 115, /* directive_repeatable_opt  */
  YYSYMBOL_directive_locations = 116,      /* directive_locations  */
  YYSYMBOL_type_system_extension = 117,    /* type_system_extension  */
  YYSYMBOL_schema_extension = 118,         /* schema_extension  */
  YYSYMBOL_type_extension = 119,           /* type_extension  */
  YYSYMBOL_scalar_type_extension = 120,    /* scalar_type_extension  */
  YYSYMBOL_object_type_extension = 121,    /* object_type_extension  */
  YYSYMBOL_interface_type_extension = 122, /* interface_type_extension  */
  YYSYMBOL_union_type_extension = 123,     /* union_type_extension  */
  YYSYMBOL_enum_type_extension = 124,      /* enum_type_extension  */
  YYSYMBOL_input_object_type_extension = 125 /* input_object_type_extension  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_int16 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if 1

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* 1 */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  77
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   781

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  86
/* YYNRULES -- Number of rules.  */
#define YYNRULES  181
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  309

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   257


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       3,     4,     5,     6,     7,     8,     9,    10,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    22,
      23,    24,    25,    26,    27,    28,    29,    30,    31,    32,
      33,    34,    35,    36,    37,    38,    39,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,    99,    99,   101,   119,   120,   121,   124,   125,   126,
     129,   130,   133,   144,   155,   168,   169,   170,   173,   174,
     177,   178,   181,   182,   185,   196,   197,   200,   201,   204,
     205,   206,   209,   212,   213,   216,   227,   240,   241,   244,
     245,   248,   258,   259,   260,   261,   262,   263,   264,   265,
     266,   269,   270,   271,   273,   281,   290,   291,   294,   295,
     298,   299,   300,   301,   302,   303,   305,   314,   323,   324,
     327,   328,   331,   342,   351,   352,   355,   356,   359,   370,
     371,   374,   375,   377,   387,   388,   391,   392,   393,   394,
     395,   396,   397,   398,   399,   402,   403,   404,   405,   406,
     407,   408,   412,   422,   431,   442,   454,   455,   458,   459,
     462,   469,   478,   479,   480,   483,   496,   497,   502,   508,
     509,   510,   511,   512,   513,   515,   518,   519,   522,   534,
     548,   549,   550,   551,   554,   562,   568,   576,   581,   595,
     596,   599,   600,   603,   617,   618,   621,   622,   623,   626,
     640,   648,   653,   666,   679,   691,   692,   695,   708,   721,
     723,   726,   727,   731,   732,   735,   746,   758,   759,   760,
     761,   762,   763,   765,   775,   787,   799,   808,   819,   828,
     839,   848
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if 1
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  static const char *const yy_sname[] =
  {
  "end of file", "error", "invalid token", "AMP", "BANG", "COLON",
  "DIRECTIVE", "DIR_SIGN", "ENUM", "ELLIPSIS", "EQUALS", "EXTEND",
  "FALSE_LITERAL", "FLOAT", "FRAGMENT", "IDENTIFIER", "INPUT",
  "IMPLEMENTS", "INT", "INTERFACE", "LBRACKET", "LCURLY", "LPAREN",
  "MUTATION", "NULL_LITERAL", "ON", "PIPE", "QUERY", "RBRACKET", "RCURLY",
  "REPEATABLE", "RPAREN", "SCALAR", "SCHEMA", "STRING", "SUBSCRIPTION",
  "TRUE_LITERAL", "TYPE_LITERAL", "UNION", "VAR_SIGN", "$accept", "start",
  "document", "definitions_list", "definition", "executable_definition",
  "operation_definition", "operation_type", "operation_name_opt",
  "variable_definitions_opt", "variable_definitions_list",
  "variable_definition", "default_value_opt", "selection_list",
  "selection", "selection_set", "selection_set_opt", "field",
  "arguments_opt", "arguments_list", "argument", "literal_value",
  "input_value", "null_value", "variable", "list_value", "list_value_list",
  "enum_name", "enum_value", "object_value", "object_value_list_opt",
  "object_value_list", "object_value_field", "object_literal_value",
  "object_literal_value_list_opt", "object_literal_value_list",
  "object_literal_value_field", "directives_list_opt", "directives_list",
  "directive", "name", "schema_keyword", "name_without_on",
  "fragment_spread", "inline_fragment", "fragment_definition",
  "fragment_name_opt", "type", "nullable_type", "type_system_definition",
  "schema_definition", "operation_type_definition_list",
  "operation_type_definition", "type_definition", "description",
  "description_opt", "scalar_type_definition", "object_type_definition",
  "implements_opt", "interfaces_list", "legacy_interfaces_list",
  "input_value_definition", "input_value_definition_list",
  "arguments_definitions_opt", "field_definition",
  "field_definition_list_opt", "field_definition_list",
  "interface_type_definition", "union_members", "union_type_definition",
  "enum_type_definition", "enum_value_definition",
  "enum_value_definitions", "input_object_type_definition",
  "directive_definition", "directive_repeatable_opt",
  "directive_locations", "type_system_extension", "schema_extension",
  "type_extension", "scalar_type_extension", "object_type_extension",
  "interface_type_extension", "union_type_extension",
  "enum_type_extension", "input_object_type_extension", YY_NULLPTR
  };
  return yy_sname[yysymbol];
}
#endif

#define YYPACT_NINF (-185)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-147)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     205,   204,   743,   479,  -185,  -185,    10,  -185,  -185,    21,
    -185,   126,  -185,  -185,  -185,   710,  -185,  -185,  -185,  -185,
    -185,    79,  -185,  -185,  -185,  -185,  -185,  -185,  -185,  -185,
    -185,  -185,  -185,  -185,  -185,  -185,  -185,  -185,   710,   710,
     710,   710,    10,   710,   710,  -185,  -185,  -185,  -185,  -185,
    -185,  -185,  -185,  -185,  -185,  -185,  -185,  -185,  -185,  -185,
    -185,  -185,     2,   578,  -185,  -185,   512,  -185,  -185,     6,
    -185,  -185,  -185,   710,    12,    10,  -185,  -185,  -185,    27,
    -185,    44,   710,   710,   710,   710,   710,   710,    10,    10,
      45,    10,    47,    22,    45,    10,   611,   611,    53,    10,
    -185,  -185,   710,   710,    10,    56,    -1,  -185,    49,    10,
     710,    10,    10,    45,    10,    45,    10,    71,    22,    83,
      22,   305,    10,    10,    -1,    10,    98,    32,   611,  -185,
      10,   109,    10,   644,  -185,  -185,    56,   677,  -185,   122,
      53,  -185,   128,    67,  -185,   710,   -16,  -185,    53,   113,
     118,   124,    10,  -185,    10,   138,   116,   116,   710,   264,
     148,   710,   131,    74,   131,   710,   135,    53,  -185,    53,
     545,    10,  -185,  -185,   412,  -185,  -185,   710,  -185,  -185,
     149,  -185,  -185,  -185,   116,   136,   116,   116,   131,   131,
     710,   250,  -185,    42,   710,  -185,    43,  -185,   148,   710,
    -185,    57,  -185,  -185,  -185,  -185,   130,  -185,  -185,  -185,
    -185,    53,  -185,  -185,  -185,  -185,  -185,   338,   710,  -185,
    -185,  -185,  -185,  -185,   710,  -185,  -185,  -185,  -185,  -185,
    -185,  -185,  -185,  -185,  -185,  -185,  -185,   611,   112,  -185,
     140,    76,    85,  -185,  -185,   130,    10,  -185,  -185,   163,
    -185,  -185,  -185,   710,  -185,   102,   710,  -185,  -185,  -185,
     378,   142,   710,  -185,   143,   710,  -185,   168,  -185,   165,
    -185,   710,  -185,  -185,  -185,   611,   113,  -185,  -185,  -185,
    -185,  -185,  -185,  -185,   173,  -185,  -185,   176,   412,   446,
    -185,  -185,   156,   165,   178,   412,   446,  -185,  -185,   710,
    -185,   710,    10,   611,  -185,  -185,  -185,    10,  -185
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       4,     0,   106,     0,    16,    15,    79,   125,    17,     0,
       2,   126,     5,     7,    10,    18,    11,     8,   112,   113,
     127,     0,   119,   120,   121,   122,   123,   124,   114,     9,
     163,   164,   167,   168,   169,   170,   171,   172,     0,     0,
       0,     0,    79,     0,     0,    94,    92,    99,    96,    95,
      93,    89,    90,    97,    87,    86,    98,    88,    91,   100,
     101,   107,     0,    79,    85,    14,     0,    27,    29,    37,
      84,    30,    31,     0,     0,    80,    81,     1,     6,    20,
      19,     0,     0,     0,     0,     0,     0,     0,    79,    79,
     130,     0,     0,   166,   130,    79,     0,     0,     0,    79,
      13,    28,     0,     0,    79,    37,     0,    82,     0,    79,
       0,    79,    79,   130,    79,   130,    79,     0,   179,     0,
     181,     0,    79,   173,     0,    79,     0,   177,     0,   110,
      79,   108,    79,     0,   104,   102,    37,     0,    39,     0,
      33,    83,     0,     0,   116,     0,     0,    22,     0,   141,
       0,     0,    79,   128,    79,     0,   126,   126,     0,   134,
     132,   133,   144,     0,   144,     0,     0,     0,   109,     0,
       0,    79,    38,    40,     0,    34,    36,     0,   115,   117,
       0,    21,    23,    12,   126,   159,   126,   126,   144,   144,
       0,     0,   155,   126,     0,   139,   126,   134,   131,     0,
     137,   126,   175,   165,   174,   150,   176,   111,   105,   103,
      32,    33,    46,    42,    61,    60,    43,     0,    68,    54,
      63,    62,    44,    45,     0,    64,    51,    41,    47,    52,
      49,    66,    48,    53,    50,    65,   118,     0,   126,   160,
       0,   126,   126,   149,   129,   152,    79,   178,   156,     0,
     180,   140,   135,     0,   147,   126,     0,    35,    56,    58,
       0,     0,    69,    70,     0,    75,    76,     0,    55,    25,
     142,     0,   153,   157,   154,     0,   141,   145,   148,   151,
      57,    59,    67,    71,     0,    73,    77,     0,     0,     0,
      24,   161,   158,    25,     0,     0,     0,    51,    72,    74,
      26,     0,    79,     0,    78,   162,   138,    79,   143
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -185,  -185,  -185,  -185,   175,  -185,  -185,    14,  -185,  -185,
    -185,    38,  -104,    65,   -64,   -94,   -12,  -185,   -89,  -185,
      63,  -164,  -171,  -185,  -185,  -185,  -185,    11,  -185,  -185,
    -185,  -185,   -58,  -185,  -185,  -185,   -57,    81,   -36,   -62,
      -3,  -167,     3,  -185,  -185,  -185,  -185,   -96,  -185,  -185,
    -185,    86,  -133,  -185,  -185,     8,  -185,  -185,   -46,    59,
    -185,  -178,   -72,   -54,   -41,  -144,  -185,  -185,    28,  -185,
    -185,  -184,    39,  -185,  -185,  -185,  -185,  -185,  -185,  -185,
    -185,  -185,  -185,  -185,  -185,  -185
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,     9,    10,    11,    12,    13,    14,    59,    79,   109,
     146,   147,   290,    66,    67,   175,   176,    68,   104,   137,
     138,   226,   298,   228,   229,   230,   260,   231,   232,   233,
     261,   262,   263,   234,   264,   265,   266,    74,    75,    76,
     129,    60,    70,    71,    72,    16,    62,   130,   131,    17,
      18,   143,   144,    19,    20,   194,    22,    23,   122,   160,
     161,   195,   196,   185,   254,   202,   255,    24,   206,    25,
      26,   192,   193,    27,    28,   240,   292,    29,    30,    31,
      32,    33,    34,    35,    36,    37
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      69,   132,   101,   227,   134,    61,    93,   235,    21,   248,
     179,   102,    80,   107,    15,   181,   141,    73,   251,    21,
     204,    77,     4,   145,   235,    15,     5,    96,   103,    73,
     179,   107,   166,   106,     8,    88,    89,    90,    91,    73,
      94,    95,   -80,   -80,   243,   244,   259,   171,   125,   108,
     235,   110,   118,   120,   183,   123,   107,   248,   107,   127,
     251,   107,   121,    69,   251,   107,    99,   152,   124,   154,
     105,   247,   250,   208,   133,   209,     7,     7,   103,   111,
     112,   113,   114,   115,   116,    81,  -146,    82,   145,   281,
       4,     7,   156,   235,     5,    83,   178,     4,    84,   136,
     139,     5,     8,   203,   157,   272,   101,   149,   165,     8,
       7,    85,   238,   168,   273,   242,    86,    87,   159,     7,
     142,   235,   235,    92,   297,   300,    -3,   174,   235,   235,
      69,   277,   304,   177,   139,   184,     7,     1,   142,   186,
       2,   269,   180,   270,    98,   187,     7,     3,   190,     4,
       7,   199,   201,     5,   237,   197,   256,   142,   200,     6,
       7,     8,   205,   207,   191,   271,   239,    69,   275,   117,
     119,   282,   285,   288,   236,   289,   126,   142,   295,   293,
     135,   296,   301,   303,   182,   140,    78,   205,   225,   302,
     148,   249,   150,   151,   191,   153,   252,   155,   170,   257,
     173,   191,   246,   162,   283,   225,   164,   307,   286,   253,
     163,   167,    38,   169,   278,   267,     1,   198,   245,     2,
      39,   268,   294,    40,     0,   241,     3,     0,     4,     0,
       0,   225,     5,   188,     0,   189,    41,    42,     6,     7,
       8,    43,    44,     0,     0,     0,     0,     0,     0,   191,
     276,     0,   211,   279,     0,     0,    45,     0,    46,   284,
       0,     0,   287,   253,   214,   215,    50,    51,   291,    52,
       0,     0,     0,     4,   225,   220,  -136,     5,     0,  -136,
     221,  -136,    54,    55,     0,     8,     0,    57,    58,  -136,
       0,     0,     0,     0,  -136,     0,   287,     0,   305,     0,
    -136,     0,   225,   225,     0,     0,     0,     0,   158,   225,
     225,    45,     0,    46,     0,     0,     0,    47,     0,    48,
      49,    50,    51,     0,    52,     0,     0,   274,     4,     0,
      64,     0,     5,     0,     0,    53,     0,    54,    55,     0,
       8,    56,    57,    58,    45,     0,    46,     0,     0,     0,
     212,   213,   214,   215,    50,    51,   216,    52,   217,   218,
       0,     4,   219,   220,     0,     5,   258,     0,   221,     0,
      54,    55,   222,     8,   223,    57,    58,   224,     0,     0,
       0,     0,     0,   306,    45,     0,    46,     0,   308,     0,
     212,   213,   214,   215,    50,    51,   216,    52,   217,   218,
       0,     4,   219,   220,     0,     5,   280,     0,   221,     0,
      54,    55,   222,     8,   223,    57,    58,   224,    45,     0,
      46,     0,     0,     0,   212,   213,   214,   215,    50,    51,
     216,    52,   217,   218,     0,     4,   219,   220,     0,     5,
       0,     0,   221,     0,    54,    55,   222,     8,   223,    57,
      58,   224,    45,     0,    46,     0,     0,     0,   212,   213,
     214,   215,    50,    51,   216,    52,   217,   299,     0,     4,
     219,   220,     0,     5,     0,     0,   221,     0,    54,    55,
     222,     8,   223,    57,    58,    45,     0,    46,    63,     0,
       0,    47,     0,    48,    49,    50,    51,     0,    52,     0,
       0,     0,     4,     0,    64,     0,     5,     0,    65,    53,
       0,    54,    55,     0,     8,    56,    57,    58,    45,     0,
      46,    63,     0,     0,    47,     0,    48,    49,    50,    51,
       0,    52,     0,     0,     0,     4,     0,    64,     0,     5,
       0,   100,    53,     0,    54,    55,     0,     8,    56,    57,
      58,    45,     0,    46,    63,     0,     0,    47,     0,    48,
      49,    50,    51,     0,    52,     0,     0,     0,     4,     0,
      64,     0,     5,     0,   210,    53,     0,    54,    55,     0,
       8,    56,    57,    58,    45,    73,    46,     0,     0,     0,
      47,     0,    48,    49,    50,    51,     0,    52,     0,     0,
       0,     4,     0,    97,     0,     5,     0,     0,    53,     0,
      54,    55,     0,     8,    56,    57,    58,    45,     0,    46,
       0,     0,     0,    47,     0,    48,    49,    50,    51,     0,
      52,   128,     0,     0,     4,     0,    64,     0,     5,     0,
       0,    53,     0,    54,    55,     0,     8,    56,    57,    58,
      45,     0,    46,    63,     0,     0,    47,     0,    48,    49,
      50,    51,     0,    52,     0,     0,     0,     4,     0,    64,
       0,     5,     0,     0,    53,     0,    54,    55,     0,     8,
      56,    57,    58,    45,     0,    46,     0,     0,     0,    47,
       0,    48,    49,    50,    51,     0,    52,     0,     0,     0,
       4,     0,    64,     0,     5,     0,     0,    53,   172,    54,
      55,     0,     8,    56,    57,    58,    45,     0,    46,     0,
       0,     0,    47,     0,    48,    49,    50,    51,     0,    52,
       0,     0,     0,     4,     0,    64,     0,     5,     0,     0,
      53,     0,    54,    55,     0,     8,    56,    57,    58,    45,
       0,    46,     0,     0,     0,    47,     0,    48,    49,    50,
      51,     0,    52,     0,     0,     0,     4,     0,     0,     0,
       5,     0,     0,    53,     0,    54,    55,     0,     8,    56,
      57,    58
};

static const yytype_int16 yycheck[] =
{
       3,    97,    66,   174,    98,     2,    42,   174,     0,   193,
     143,     5,    15,    75,     0,    31,   105,     7,   196,    11,
     164,     0,    23,    39,   191,    11,    27,    25,    22,     7,
     163,    93,   128,    21,    35,    38,    39,    40,    41,     7,
      43,    44,    10,    21,   188,   189,   217,   136,    94,    22,
     217,     7,    88,    89,   148,    91,   118,   241,   120,    95,
     238,   123,    17,    66,   242,   127,    63,   113,    21,   115,
      73,    29,    29,   167,    21,   169,    34,    34,    22,    82,
      83,    84,    85,    86,    87,     6,    29,     8,    39,   260,
      23,    34,    21,   260,    27,    16,    29,    23,    19,   102,
     103,    27,    35,    29,    21,    29,   170,   110,    10,    35,
      34,    32,   184,     4,    29,   187,    37,    38,   121,    34,
     106,   288,   289,    42,   288,   289,     0,     5,   295,   296,
     133,    29,   296,     5,   137,    22,    34,    11,   124,    21,
      14,   237,   145,    31,    63,    21,    34,    21,    10,    23,
      34,     3,    21,    27,     5,   158,    26,   143,   161,    33,
      34,    35,   165,    28,   156,    25,    30,   170,     5,    88,
      89,    29,    29,     5,   177,    10,    95,   163,     5,   275,
      99,     5,    26,     5,   146,   104,    11,   190,   174,   293,
     109,   194,   111,   112,   186,   114,   199,   116,   133,   211,
     137,   193,   191,   122,   262,   191,   125,   303,   265,   201,
     124,   130,     8,   132,   255,   218,    11,   158,   190,    14,
      16,   224,   276,    19,    -1,   186,    21,    -1,    23,    -1,
      -1,   217,    27,   152,    -1,   154,    32,    33,    33,    34,
      35,    37,    38,    -1,    -1,    -1,    -1,    -1,    -1,   241,
     253,    -1,   171,   256,    -1,    -1,     6,    -1,     8,   262,
      -1,    -1,   265,   255,    14,    15,    16,    17,   271,    19,
      -1,    -1,    -1,    23,   260,    25,    12,    27,    -1,    15,
      30,    17,    32,    33,    -1,    35,    -1,    37,    38,    25,
      -1,    -1,    -1,    -1,    30,    -1,   299,    -1,   301,    -1,
      36,    -1,   288,   289,    -1,    -1,    -1,    -1,     3,   295,
     296,     6,    -1,     8,    -1,    -1,    -1,    12,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,   246,    23,    -1,
      25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,
      35,    36,    37,    38,     6,    -1,     8,    -1,    -1,    -1,
      12,    13,    14,    15,    16,    17,    18,    19,    20,    21,
      -1,    23,    24,    25,    -1,    27,    28,    -1,    30,    -1,
      32,    33,    34,    35,    36,    37,    38,    39,    -1,    -1,
      -1,    -1,    -1,   302,     6,    -1,     8,    -1,   307,    -1,
      12,    13,    14,    15,    16,    17,    18,    19,    20,    21,
      -1,    23,    24,    25,    -1,    27,    28,    -1,    30,    -1,
      32,    33,    34,    35,    36,    37,    38,    39,     6,    -1,
       8,    -1,    -1,    -1,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    -1,    23,    24,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    34,    35,    36,    37,
      38,    39,     6,    -1,     8,    -1,    -1,    -1,    12,    13,
      14,    15,    16,    17,    18,    19,    20,    21,    -1,    23,
      24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,
      34,    35,    36,    37,    38,     6,    -1,     8,     9,    -1,
      -1,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    -1,    25,    -1,    27,    -1,    29,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38,     6,    -1,
       8,     9,    -1,    -1,    12,    -1,    14,    15,    16,    17,
      -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,
      -1,    29,    30,    -1,    32,    33,    -1,    35,    36,    37,
      38,     6,    -1,     8,     9,    -1,    -1,    12,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,
      25,    -1,    27,    -1,    29,    30,    -1,    32,    33,    -1,
      35,    36,    37,    38,     6,     7,     8,    -1,    -1,    -1,
      12,    -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,
      -1,    23,    -1,    25,    -1,    27,    -1,    -1,    30,    -1,
      32,    33,    -1,    35,    36,    37,    38,     6,    -1,     8,
      -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,
      19,    20,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,
      -1,    30,    -1,    32,    33,    -1,    35,    36,    37,    38,
       6,    -1,     8,     9,    -1,    -1,    12,    -1,    14,    15,
      16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,    25,
      -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,    35,
      36,    37,    38,     6,    -1,     8,    -1,    -1,    -1,    12,
      -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,
      23,    -1,    25,    -1,    27,    -1,    -1,    30,    31,    32,
      33,    -1,    35,    36,    37,    38,     6,    -1,     8,    -1,
      -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,    19,
      -1,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,    -1,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    -1,    -1,    -1,
      27,    -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,
      37,    38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    11,    14,    21,    23,    27,    33,    34,    35,    41,
      42,    43,    44,    45,    46,    47,    85,    89,    90,    93,
      94,    95,    96,    97,   107,   109,   110,   113,   114,   117,
     118,   119,   120,   121,   122,   123,   124,   125,     8,    16,
      19,    32,    33,    37,    38,     6,     8,    12,    14,    15,
      16,    17,    19,    30,    32,    33,    36,    37,    38,    47,
      81,    82,    86,     9,    25,    29,    53,    54,    57,    80,
      82,    83,    84,     7,    77,    78,    79,     0,    44,    48,
      80,     6,     8,    16,    19,    32,    37,    38,    80,    80,
      80,    80,    77,    78,    80,    80,    25,    25,    77,    82,
      29,    54,     5,    22,    58,    80,    21,    79,    22,    49,
       7,    80,    80,    80,    80,    80,    80,    77,    78,    77,
      78,    17,    98,    78,    21,    98,    77,    78,    20,    80,
      87,    88,    87,    21,    55,    77,    80,    59,    60,    80,
      77,    58,    47,    91,    92,    39,    50,    51,    77,    80,
      77,    77,    98,    77,    98,    77,    21,    21,     3,    80,
      99,   100,    77,    91,    77,    10,    87,    77,     4,    77,
      53,    58,    31,    60,     5,    55,    56,     5,    29,    92,
      80,    31,    51,    55,    22,   103,    21,    21,    77,    77,
      10,    95,   111,   112,    95,   101,   102,    80,    99,     3,
      80,    21,   105,    29,   105,    80,   108,    28,    55,    55,
      29,    77,    12,    13,    14,    15,    18,    20,    21,    24,
      25,    30,    34,    36,    39,    47,    61,    62,    63,    64,
      65,    67,    68,    69,    73,    81,    80,     5,   102,    30,
     115,   112,   102,   105,   105,   108,    67,    29,   111,    80,
      29,   101,    80,    95,   104,   106,    26,    56,    28,    62,
      66,    70,    71,    72,    74,    75,    76,    80,    80,    87,
      31,    25,    29,    29,    77,     5,    80,    29,   104,    80,
      28,    62,    29,    72,    80,    29,    76,    80,     5,    10,
      52,    80,   116,    87,   103,     5,     5,    61,    62,    21,
      61,    26,    52,     5,    61,    80,    77,    87,    77
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    43,    44,    44,    44,
      45,    45,    46,    46,    46,    47,    47,    47,    48,    48,
      49,    49,    50,    50,    51,    52,    52,    53,    53,    54,
      54,    54,    55,    56,    56,    57,    57,    58,    58,    59,
      59,    60,    61,    61,    61,    61,    61,    61,    61,    61,
      61,    62,    62,    62,    63,    64,    65,    65,    66,    66,
      67,    67,    67,    67,    67,    67,    68,    69,    70,    70,
      71,    71,    72,    73,    74,    74,    75,    75,    76,    77,
      77,    78,    78,    79,    80,    80,    81,    81,    81,    81,
      81,    81,    81,    81,    81,    82,    82,    82,    82,    82,
      82,    82,    83,    84,    84,    85,    86,    86,    87,    87,
      88,    88,    89,    89,    89,    90,    91,    91,    92,    93,
      93,    93,    93,    93,    93,    94,    95,    95,    96,    97,
      98,    98,    98,    98,    99,    99,   100,   100,   101,   102,
     102,   103,   103,   104,   105,   105,   106,   106,   106,   107,
     108,   108,   109,   110,   111,   112,   112,   113,   114,   115,
     115,   116,   116,   117,   117,   118,   118,   119,   119,   119,
     119,   119,   119,   120,   121,   122,   123,   123,   124,   124,
     125,   125
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     0,     1,     2,     1,     1,     1,
       1,     1,     5,     3,     2,     1,     1,     1,     0,     1,
       0,     3,     1,     2,     5,     0,     2,     1,     2,     1,
       1,     1,     3,     0,     1,     6,     4,     0,     3,     1,
       2,     3,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     2,     2,     3,     1,     2,
       1,     1,     1,     1,     1,     1,     1,     3,     0,     1,
       1,     2,     3,     3,     0,     1,     1,     2,     3,     0,
       1,     1,     2,     3,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     3,     5,     3,     6,     0,     1,     1,     2,
       1,     3,     1,     1,     1,     5,     1,     2,     3,     1,
       1,     1,     1,     1,     1,     1,     0,     1,     4,     6,
       0,     3,     2,     2,     1,     3,     1,     2,     6,     1,
       2,     0,     3,     6,     0,     3,     0,     1,     2,     6,
       1,     3,     6,     7,     3,     1,     2,     7,     8,     0,
       1,     1,     3,     1,     1,     6,     3,     1,     1,     1,
       1,     1,     1,     4,     6,     6,     6,     4,     7,     4,
       7,     4
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (parser, YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value, parser); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, VALUE parser)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (parser);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, VALUE parser)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep, parser);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule, VALUE parser)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)], parser);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, parser); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif


/* Context of a parse error.  */
typedef struct
{
  yy_state_t *yyssp;
  yysymbol_kind_t yytoken;
} yypcontext_t;

/* Put in YYARG at most YYARGN of the expected tokens given the
   current YYCTX, and return the number of tokens stored in YYARG.  If
   YYARG is null, return the number of expected tokens (guaranteed to
   be less than YYNTOKENS).  Return YYENOMEM on memory exhaustion.
   Return 0 if there are more than YYARGN expected tokens, yet fill
   YYARG up to YYARGN. */
static int
yypcontext_expected_tokens (const yypcontext_t *yyctx,
                            yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  int yyn = yypact[+*yyctx->yyssp];
  if (!yypact_value_is_default (yyn))
    {
      /* Start YYX at -YYN if negative to avoid negative indexes in
         YYCHECK.  In other words, skip the first -YYN actions for
         this state because they are default actions.  */
      int yyxbegin = yyn < 0 ? -yyn : 0;
      /* Stay within bounds of both yycheck and yytname.  */
      int yychecklim = YYLAST - yyn + 1;
      int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
      int yyx;
      for (yyx = yyxbegin; yyx < yyxend; ++yyx)
        if (yycheck[yyx + yyn] == yyx && yyx != YYSYMBOL_YYerror
            && !yytable_value_is_error (yytable[yyx + yyn]))
          {
            if (!yyarg)
              ++yycount;
            else if (yycount == yyargn)
              return 0;
            else
              yyarg[yycount++] = YY_CAST (yysymbol_kind_t, yyx);
          }
    }
  if (yyarg && yycount == 0 && 0 < yyargn)
    yyarg[0] = YYSYMBOL_YYEMPTY;
  return yycount;
}




#ifndef yystrlen
# if defined __GLIBC__ && defined _STRING_H
#  define yystrlen(S) (YY_CAST (YYPTRDIFF_T, strlen (S)))
# else
/* Return the length of YYSTR.  */
static YYPTRDIFF_T
yystrlen (const char *yystr)
{
  YYPTRDIFF_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
# endif
#endif

#ifndef yystpcpy
# if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#  define yystpcpy stpcpy
# else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
yystpcpy (char *yydest, const char *yysrc)
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
# endif
#endif



static int
yy_syntax_error_arguments (const yypcontext_t *yyctx,
                           yysymbol_kind_t yyarg[], int yyargn)
{
  /* Actual size of YYARG. */
  int yycount = 0;
  /* There are many possibilities here to consider:
     - If this state is a consistent state with a default action, then
       the only way this function was invoked is if the default action
       is an error action.  In that case, don't check for expected
       tokens because there are none.
     - The only way there can be no lookahead present (in yychar) is if
       this state is a consistent state with a default action.  Thus,
       detecting the absence of a lookahead is sufficient to determine
       that there is no unexpected or expected token to report.  In that
       case, just report a simple "syntax error".
     - Don't assume there isn't a lookahead just because this state is a
       consistent state with a default action.  There might have been a
       previous inconsistent state, consistent state with a non-default
       action, or user semantic action that manipulated yychar.
     - Of course, the expected token list depends on states to have
       correct lookahead information, and it depends on the parser not
       to perform extra reductions after fetching a lookahead from the
       scanner and before detecting a syntax error.  Thus, state merging
       (from LALR or IELR) and default reductions corrupt the expected
       token list.  However, the list is correct for canonical LR with
       one exception: it will still contain any token that will not be
       accepted due to an error action in a later state.
  */
  if (yyctx->yytoken != YYSYMBOL_YYEMPTY)
    {
      int yyn;
      if (yyarg)
        yyarg[yycount] = yyctx->yytoken;
      ++yycount;
      yyn = yypcontext_expected_tokens (yyctx,
                                        yyarg ? yyarg + 1 : yyarg, yyargn - 1);
      if (yyn == YYENOMEM)
        return YYENOMEM;
      else
        yycount += yyn;
    }
  return yycount;
}

/* Copy into *YYMSG, which is of size *YYMSG_ALLOC, an error message
   about the unexpected token YYTOKEN for the state stack whose top is
   YYSSP.

   Return 0 if *YYMSG was successfully written.  Return -1 if *YYMSG is
   not large enough to hold the message.  In that case, also set
   *YYMSG_ALLOC to the required number of bytes.  Return YYENOMEM if the
   required number of bytes is too large to store.  */
static int
yysyntax_error (YYPTRDIFF_T *yymsg_alloc, char **yymsg,
                const yypcontext_t *yyctx)
{
  enum { YYARGS_MAX = 5 };
  /* Internationalized format string. */
  const char *yyformat = YY_NULLPTR;
  /* Arguments of yyformat: reported tokens (one for the "unexpected",
     one per "expected"). */
  yysymbol_kind_t yyarg[YYARGS_MAX];
  /* Cumulated lengths of YYARG.  */
  YYPTRDIFF_T yysize = 0;

  /* Actual size of YYARG. */
  int yycount = yy_syntax_error_arguments (yyctx, yyarg, YYARGS_MAX);
  if (yycount == YYENOMEM)
    return YYENOMEM;

  switch (yycount)
    {
#define YYCASE_(N, S)                       \
      case N:                               \
        yyformat = S;                       \
        break
    default: /* Avoid compiler warnings. */
      YYCASE_(0, YY_("syntax error"));
      YYCASE_(1, YY_("syntax error, unexpected %s"));
      YYCASE_(2, YY_("syntax error, unexpected %s, expecting %s"));
      YYCASE_(3, YY_("syntax error, unexpected %s, expecting %s or %s"));
      YYCASE_(4, YY_("syntax error, unexpected %s, expecting %s or %s or %s"));
      YYCASE_(5, YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s"));
#undef YYCASE_
    }

  /* Compute error message size.  Don't count the "%s"s, but reserve
     room for the terminator.  */
  yysize = yystrlen (yyformat) - 2 * yycount + 1;
  {
    int yyi;
    for (yyi = 0; yyi < yycount; ++yyi)
      {
        YYPTRDIFF_T yysize1
          = yysize + yystrlen (yysymbol_name (yyarg[yyi]));
        if (yysize <= yysize1 && yysize1 <= YYSTACK_ALLOC_MAXIMUM)
          yysize = yysize1;
        else
          return YYENOMEM;
      }
  }

  if (*yymsg_alloc < yysize)
    {
      *yymsg_alloc = 2 * yysize;
      if (! (yysize <= *yymsg_alloc
             && *yymsg_alloc <= YYSTACK_ALLOC_MAXIMUM))
        *yymsg_alloc = YYSTACK_ALLOC_MAXIMUM;
      return -1;
    }

  /* Avoid sprintf, as that infringes on the user's name space.
     Don't have undefined behavior even if the translation
     produced a string with the wrong number of "%s"s.  */
  {
    char *yyp = *yymsg;
    int yyi = 0;
    while ((*yyp = *yyformat) != '\0')
      if (*yyp == '%' && yyformat[1] == 's' && yyi < yycount)
        {
          yyp = yystpcpy (yyp, yysymbol_name (yyarg[yyi++]));
          yyformat += 2;
        }
      else
        {
          ++yyp;
          ++yyformat;
        }
  }
  return 0;
}


/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, VALUE parser)
{
  YY_USE (yyvaluep);
  YY_USE (parser);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}






/*----------.
| yyparse.  |
`----------*/

int
yyparse (VALUE parser)
{
/* Lookahead token kind.  */
int yychar;


/* The semantic value of the lookahead symbol.  */
/* Default value used for initialization, for pacifying older GCCs
   or non-GCC compilers.  */
YY_INITIAL_VALUE (static YYSTYPE yyval_default;)
YYSTYPE yylval YY_INITIAL_VALUE (= yyval_default);

    /* Number of syntax errors so far.  */
    int yynerrs = 0;

    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYPTRDIFF_T yymsg_alloc = sizeof yymsgbuf;

#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex (&yylval, parser);
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 2: /* start: document  */
#line 99 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { rb_ivar_set(parser, rb_intern("@result"), yyvsp[0]); }
#line 1909 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 3: /* document: definitions_list  */
#line 101 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
    VALUE position_source = rb_ary_entry(yyvsp[0], 0);
    VALUE line, col;
    if (RB_TEST(position_source)) {
      line = rb_funcall(position_source, rb_intern("line"), 0);
      col = rb_funcall(position_source, rb_intern("col"), 0);
    } else {
      line = INT2FIX(1);
      col = INT2FIX(1);
    }
    yyval = rb_funcall(GraphQL_Language_Nodes_Document, rb_intern("from_a"), 3,
      line,
      col,
      yyvsp[0]
    );
  }
#line 1930 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 4: /* definitions_list: %empty  */
#line 119 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new(); }
#line 1936 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 5: /* definitions_list: definition  */
#line 120 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1942 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 6: /* definitions_list: definitions_list definition  */
#line 121 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 1948 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 12: /* operation_definition: operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set  */
#line 133 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                   {
        yyval = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          (RB_TEST(yyvsp[-3]) ? rb_ary_entry(yyvsp[-3], 3) : Qnil),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 1964 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 13: /* operation_definition: LCURLY selection_list RCURLY  */
#line 144 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   {
        yyval = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          yyvsp[-1]
        );
      }
#line 1980 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 14: /* operation_definition: LCURLY RCURLY  */
#line 155 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    {
        yyval = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-1], 1),
          rb_ary_entry(yyvsp[-1], 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE
        );
      }
#line 1996 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 18: /* operation_name_opt: %empty  */
#line 173 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2002 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 20: /* variable_definitions_opt: %empty  */
#line 177 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = GraphQL_Language_Nodes_NONE; }
#line 2008 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 21: /* variable_definitions_opt: LPAREN variable_definitions_list RPAREN  */
#line 178 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = yyvsp[-1]; }
#line 2014 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 22: /* variable_definitions_list: variable_definition  */
#line 181 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2020 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 23: /* variable_definitions_list: variable_definitions_list variable_definition  */
#line 182 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 2026 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 24: /* variable_definition: VAR_SIGN name COLON type default_value_opt  */
#line 185 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_VariableDefinition, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2040 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 25: /* default_value_opt: %empty  */
#line 196 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = Qnil; }
#line 2046 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 26: /* default_value_opt: EQUALS literal_value  */
#line 197 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = yyvsp[0]; }
#line 2052 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 27: /* selection_list: selection  */
#line 200 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2058 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 28: /* selection_list: selection_list selection  */
#line 201 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2064 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 32: /* selection_set: LCURLY selection_list RCURLY  */
#line 209 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   { yyval = yyvsp[-1]; }
#line 2070 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 33: /* selection_set_opt: %empty  */
#line 212 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = rb_ary_new(); }
#line 2076 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 35: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 216 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                        {
      yyval = rb_funcall(GraphQL_Language_Nodes_Field, rb_intern("from_a"), 7,
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        rb_ary_entry(yyvsp[-5], 3), // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 2092 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 36: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 227 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      yyval = rb_funcall(GraphQL_Language_Nodes_Field, rb_intern("from_a"), 7,
        rb_ary_entry(yyvsp[-3], 1),
        rb_ary_entry(yyvsp[-3], 2),
        Qnil, // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 2108 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 37: /* arguments_opt: %empty  */
#line 240 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = GraphQL_Language_Nodes_NONE; }
#line 2114 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 38: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 241 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = yyvsp[-1]; }
#line 2120 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 39: /* arguments_list: argument  */
#line 244 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2126 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 40: /* arguments_list: arguments_list argument  */
#line 245 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { rb_ary_push(yyval, yyvsp[0]); }
#line 2132 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 41: /* argument: name COLON input_value  */
#line 248 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2145 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 42: /* literal_value: FLOAT  */
#line 258 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_f"), 0); }
#line 2151 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 43: /* literal_value: INT  */
#line 259 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_i"), 0); }
#line 2157 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 44: /* literal_value: STRING  */
#line 260 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2163 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 45: /* literal_value: TRUE_LITERAL  */
#line 261 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qtrue; }
#line 2169 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 46: /* literal_value: FALSE_LITERAL  */
#line 262 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qfalse; }
#line 2175 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 54: /* null_value: NULL_LITERAL  */
#line 273 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                           {
    yyval = rb_funcall(GraphQL_Language_Nodes_NullValue, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2187 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 55: /* variable: VAR_SIGN name  */
#line 281 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          {
    yyval = rb_funcall(GraphQL_Language_Nodes_VariableIdentifier, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[-1], 1),
      rb_ary_entry(yyvsp[-1], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2199 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 56: /* list_value: LBRACKET RBRACKET  */
#line 290 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2205 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 57: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 291 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[-1]; }
#line 2211 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 58: /* list_value_list: input_value  */
#line 294 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2217 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 59: /* list_value_list: list_value_list input_value  */
#line 295 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 2223 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 66: /* enum_value: enum_name  */
#line 305 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        {
    yyval = rb_funcall(GraphQL_Language_Nodes_Enum, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2235 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 67: /* object_value: LCURLY object_value_list_opt RCURLY  */
#line 314 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
      yyval = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
        rb_ary_entry(yyvsp[-2], 1),
        rb_ary_entry(yyvsp[-2], 2),
        yyvsp[-1]
      );
    }
#line 2247 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 68: /* object_value_list_opt: %empty  */
#line 323 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2253 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 70: /* object_value_list: object_value_field  */
#line 327 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2259 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 71: /* object_value_list: object_value_list object_value_field  */
#line 328 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2265 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 72: /* object_value_field: name COLON input_value  */
#line 331 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2278 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 73: /* object_literal_value: LCURLY object_literal_value_list_opt RCURLY  */
#line 342 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          yyvsp[-1]
        );
      }
#line 2290 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 74: /* object_literal_value_list_opt: %empty  */
#line 351 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2296 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 76: /* object_literal_value_list: object_literal_value_field  */
#line 355 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2302 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 77: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 356 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2308 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 78: /* object_literal_value_field: name COLON literal_value  */
#line 359 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2321 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 79: /* directives_list_opt: %empty  */
#line 370 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = GraphQL_Language_Nodes_NONE; }
#line 2327 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 81: /* directives_list: directive  */
#line 374 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2333 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 82: /* directives_list: directives_list directive  */
#line 375 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2339 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 83: /* directive: DIR_SIGN name arguments_opt  */
#line 377 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                         {
    yyval = rb_funcall(GraphQL_Language_Nodes_Directive, rb_intern("from_a"), 4,
      rb_ary_entry(yyvsp[-2], 1),
      rb_ary_entry(yyvsp[-2], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2352 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 102: /* fragment_spread: ELLIPSIS name_without_on directives_list_opt  */
#line 412 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   {
        yyval = rb_funcall(GraphQL_Language_Nodes_FragmentSpread, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0]
        );
      }
#line 2365 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 103: /* inline_fragment: ELLIPSIS ON type directives_list_opt selection_set  */
#line 422 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         {
        yyval = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2379 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 104: /* inline_fragment: ELLIPSIS directives_list_opt selection_set  */
#line 431 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2393 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 105: /* fragment_definition: FRAGMENT fragment_name_opt ON type directives_list_opt selection_set  */
#line 442 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                         {
      yyval = rb_funcall(GraphQL_Language_Nodes_FragmentDefinition, rb_intern("from_a"), 6,
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        yyvsp[-4],
        yyvsp[-2],
        yyvsp[-1],
        yyvsp[0]
      );
    }
#line 2408 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 106: /* fragment_name_opt: %empty  */
#line 454 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2414 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 107: /* fragment_name_opt: name_without_on  */
#line 455 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2420 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 109: /* type: nullable_type BANG  */
#line 459 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_funcall(GraphQL_Language_Nodes_NonNullType, rb_intern("from_a"), 3, rb_funcall(yyvsp[-1], rb_intern("line"), 0), rb_funcall(yyvsp[-1], rb_intern("col"), 0), yyvsp[-1]); }
#line 2426 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 110: /* nullable_type: name  */
#line 462 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2438 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 111: /* nullable_type: LBRACKET type RBRACKET  */
#line 469 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_ListType, rb_intern("from_a"), 3,
          rb_funcall(yyvsp[-1], rb_intern("line"), 0),
          rb_funcall(yyvsp[-1], rb_intern("col"), 0),
          yyvsp[-1]
        );
      }
#line 2450 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 115: /* schema_definition: SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 483 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                              {
        yyval = rb_funcall(GraphQL_Language_Nodes_SchemaDefinition, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          // TODO use static strings:
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("subscription")),
          yyvsp[-3]
        );
      }
#line 2466 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 117: /* operation_type_definition_list: operation_type_definition_list operation_type_definition  */
#line 497 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      rb_funcall(yyval, rb_intern("merge!"), 1, yyvsp[-1]);
    }
#line 2474 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 118: /* operation_type_definition: operation_type COLON name  */
#line 502 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_hash_new();
        rb_hash_aset(yyval, rb_ary_entry(yyvsp[-2], 3), rb_ary_entry(yyvsp[0], 3));
      }
#line 2483 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 126: /* description_opt: %empty  */
#line 518 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = Qnil; }
#line 2489 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 128: /* scalar_type_definition: description_opt SCALAR name directives_list_opt  */
#line 522 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                      {
        yyval = rb_funcall(GraphQL_Language_Nodes_ScalarTypeDefinition, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-3]) ? rb_ary_entry(yyvsp[-3], 3) : Qnil),
          yyvsp[0]
        );
      }
#line 2504 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 129: /* object_type_definition: description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 534 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                     {
        yyval = rb_funcall(GraphQL_Language_Nodes_ObjectTypeDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2], // implements
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2521 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 130: /* implements_opt: %empty  */
#line 548 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2527 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 131: /* implements_opt: IMPLEMENTS AMP interfaces_list  */
#line 549 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                     { yyval = yyvsp[0]; }
#line 2533 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 132: /* implements_opt: IMPLEMENTS interfaces_list  */
#line 550 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                 { yyval = yyvsp[0]; }
#line 2539 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 133: /* implements_opt: IMPLEMENTS legacy_interfaces_list  */
#line 551 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[0]; }
#line 2545 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 134: /* interfaces_list: name  */
#line 554 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2558 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 135: /* interfaces_list: interfaces_list AMP name  */
#line 562 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
      VALUE new_name =  rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3));
      rb_ary_push(yyval, new_name);
    }
#line 2567 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 136: /* legacy_interfaces_list: name  */
#line 568 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2580 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 137: /* legacy_interfaces_list: legacy_interfaces_list name  */
#line 576 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  {
      rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
    }
#line 2588 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 138: /* input_value_definition: description_opt name COLON type default_value_opt directives_list_opt  */
#line 581 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                            {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputValueDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-2],
          yyvsp[-1],
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[0]
        );
      }
#line 2605 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 139: /* input_value_definition_list: input_value_definition  */
#line 595 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2611 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 140: /* input_value_definition_list: input_value_definition_list input_value_definition  */
#line 596 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { rb_ary_push(yyval, yyvsp[0]); }
#line 2617 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 141: /* arguments_definitions_opt: %empty  */
#line 599 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2623 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 142: /* arguments_definitions_opt: LPAREN input_value_definition_list RPAREN  */
#line 600 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = yyvsp[-1]; }
#line 2629 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 143: /* field_definition: description_opt name arguments_definitions_opt COLON type directives_list_opt  */
#line 603 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                    {
        yyval = rb_funcall(GraphQL_Language_Nodes_FieldDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-1],
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-3],
          yyvsp[0]
        );
      }
#line 2646 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 144: /* field_definition_list_opt: %empty  */
#line 617 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2652 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 145: /* field_definition_list_opt: LCURLY field_definition_list RCURLY  */
#line 618 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          { yyval = yyvsp[-1]; }
#line 2658 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 146: /* field_definition_list: %empty  */
#line 621 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2664 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 147: /* field_definition_list: field_definition  */
#line 622 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2670 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 148: /* field_definition_list: field_definition_list field_definition  */
#line 623 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { rb_ary_push(yyval, yyvsp[0]); }
#line 2676 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 149: /* interface_type_definition: description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 626 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                  {
        yyval = rb_funcall(GraphQL_Language_Nodes_InterfaceTypeDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2693 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 150: /* union_members: name  */
#line 640 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_member = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_member);
      }
#line 2706 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 151: /* union_members: union_members PIPE name  */
#line 648 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              {
        rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
      }
#line 2714 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 152: /* union_type_definition: description_opt UNION name directives_list_opt EQUALS union_members  */
#line 653 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                          {
        yyval = rb_funcall(GraphQL_Language_Nodes_UnionTypeDefinition, rb_intern("from_a"),  6,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[0], // types
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-2]
        );
      }
#line 2730 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 153: /* enum_type_definition: description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 666 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = rb_funcall(GraphQL_Language_Nodes_EnumTypeDefinition, rb_intern("from_a"),  6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2746 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 154: /* enum_value_definition: description_opt enum_name directives_list_opt  */
#line 679 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
      yyval = rb_funcall(GraphQL_Language_Nodes_EnumValueDefinition, rb_intern("from_a"), 5,
        rb_ary_entry(yyvsp[-1], 1),
        rb_ary_entry(yyvsp[-1], 2),
        rb_ary_entry(yyvsp[-1], 3),
        // TODO see get_description for reading a description from comments
        (RB_TEST(yyvsp[-2]) ? rb_ary_entry(yyvsp[-2], 3) : Qnil),
        yyvsp[0]
      );
    }
#line 2761 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 155: /* enum_value_definitions: enum_value_definition  */
#line 691 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2767 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 156: /* enum_value_definitions: enum_value_definitions enum_value_definition  */
#line 692 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { rb_ary_push(yyval, yyvsp[0]); }
#line 2773 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 157: /* input_object_type_definition: description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 695 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                               {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputObjectTypeDefinition, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2789 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 158: /* directive_definition: description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations  */
#line 708 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                                        {
        yyval = rb_funcall(GraphQL_Language_Nodes_DirectiveDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          (RB_TEST(yyvsp[-2]) ? Qtrue : Qfalse), // repeatable
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-7]) ? rb_ary_entry(yyvsp[-7], 3) : Qnil),
          yyvsp[-3],
          yyvsp[0]
        );
      }
#line 2806 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 161: /* directive_locations: name  */
#line 726 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2812 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 162: /* directive_locations: directive_locations PIPE name  */
#line 727 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2818 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 165: /* schema_extension: EXTEND SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 735 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                     {
        yyval = rb_funcall(GraphQL_Language_Nodes_SchemaExtension, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          // TODO use static strings:
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("subscription")),
          yyvsp[-3]
        );
      }
#line 2834 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 166: /* schema_extension: EXTEND SCHEMA directives_list  */
#line 746 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    {
        yyval = rb_funcall(GraphQL_Language_Nodes_SchemaExtension, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          Qnil,
          Qnil,
          yyvsp[0]
        );
      }
#line 2849 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 173: /* scalar_type_extension: EXTEND SCALAR name directives_list  */
#line 765 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            {
    yyval = rb_funcall(GraphQL_Language_Nodes_ScalarTypeExtension, rb_intern("from_a"), 4,
      rb_ary_entry(yyvsp[-3], 1),
      rb_ary_entry(yyvsp[-3], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2862 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 174: /* object_type_extension: EXTEND TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 775 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                            {
        yyval = rb_funcall(GraphQL_Language_Nodes_ObjectTypeExtension, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2], // implements
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2877 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 175: /* interface_type_extension: EXTEND INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 787 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = rb_funcall(GraphQL_Language_Nodes_InterfaceTypeExtension, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2892 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 176: /* union_type_extension: EXTEND UNION name directives_list_opt EQUALS union_members  */
#line 799 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_UnionTypeExtension, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[0], // types
          yyvsp[-2]
        );
      }
#line 2906 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 177: /* union_type_extension: EXTEND UNION name directives_list  */
#line 808 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
        yyval = rb_funcall(GraphQL_Language_Nodes_UnionTypeExtension, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          GraphQL_Language_Nodes_NONE, // types
          yyvsp[0]
        );
      }
#line 2920 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 178: /* enum_type_extension: EXTEND ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 819 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                {
        yyval = rb_funcall(GraphQL_Language_Nodes_EnumTypeExtension, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2934 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 179: /* enum_type_extension: EXTEND ENUM name directives_list  */
#line 828 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                       {
        yyval = rb_funcall(GraphQL_Language_Nodes_EnumTypeExtension, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0],
          GraphQL_Language_Nodes_NONE
        );
      }
#line 2948 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 180: /* input_object_type_extension: EXTEND INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 839 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                      {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputObjectTypeExtension, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2962 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 181: /* input_object_type_extension: EXTEND INPUT name directives_list  */
#line 848 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputObjectTypeExtension, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0],
          GraphQL_Language_Nodes_NONE
        );
      }
#line 2976 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;


#line 2980 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      {
        yypcontext_t yyctx
          = {yyssp, yytoken};
        char const *yymsgp = YY_("syntax error");
        int yysyntax_error_status;
        yysyntax_error_status = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
        if (yysyntax_error_status == 0)
          yymsgp = yymsg;
        else if (yysyntax_error_status == -1)
          {
            if (yymsg != yymsgbuf)
              YYSTACK_FREE (yymsg);
            yymsg = YY_CAST (char *,
                             YYSTACK_ALLOC (YY_CAST (YYSIZE_T, yymsg_alloc)));
            if (yymsg)
              {
                yysyntax_error_status
                  = yysyntax_error (&yymsg_alloc, &yymsg, &yyctx);
                yymsgp = yymsg;
              }
            else
              {
                yymsg = yymsgbuf;
                yymsg_alloc = sizeof yymsgbuf;
                yysyntax_error_status = YYENOMEM;
              }
          }
        yyerror (parser, yymsgp);
        if (yysyntax_error_status == YYENOMEM)
          YYNOMEM;
      }
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval, parser);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, parser);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (parser, YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval, parser);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, parser);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  if (yymsg != yymsgbuf)
    YYSTACK_FREE (yymsg);
  return yyresult;
}

#line 858 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"


// Custom functions
int yylex (YYSTYPE *lvalp, VALUE parser) {
  int next_token_idx = FIX2INT(rb_ivar_get(parser, rb_intern("@next_token_index")));
  VALUE tokens = rb_ivar_get(parser, rb_intern("@tokens"));
  VALUE next_token = rb_ary_entry(tokens, next_token_idx);

  if (!RB_TEST(next_token)) {
    return YYEOF;
  }
  rb_ivar_set(parser, rb_intern("@next_token_index"), INT2FIX(next_token_idx + 1));
  VALUE token_type_rb_int = rb_ary_entry(next_token, 5);
  int next_token_type = FIX2INT(token_type_rb_int);

  *lvalp = next_token;
  return next_token_type;
}

void yyerror(VALUE parser, const char *msg) {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE mCParser = rb_const_get_at(mGraphQL, rb_intern("CParser"));
  VALUE rb_message = rb_str_new_cstr(msg);
  VALUE exception = rb_funcall(
      mCParser, rb_intern("prepare_parse_error"), 2,
      rb_message,
      parser
  );
  rb_exc_raise(exception);
}

#define INITIALIZE_NODE_CLASS_VARIABLE(node_class_name) GraphQL_Language_Nodes_##node_class_name = rb_const_get_at(mGraphQLLanguageNodes, rb_intern(#node_class_name));

void initialize_node_class_variables() {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE mGraphQLLanguage = rb_const_get_at(mGraphQL, rb_intern("Language"));
  VALUE mGraphQLLanguageNodes = rb_const_get_at(mGraphQLLanguage, rb_intern("Nodes"));
  GraphQL_Language_Nodes_NONE = rb_const_get_at(mGraphQLLanguageNodes, rb_intern("NONE"));
  r_string_query = rb_str_new_cstr("query");
  rb_global_variable(&r_string_query);
  rb_str_freeze(r_string_query);

  INITIALIZE_NODE_CLASS_VARIABLE(Argument)
  INITIALIZE_NODE_CLASS_VARIABLE(Directive)
  INITIALIZE_NODE_CLASS_VARIABLE(Document)
  INITIALIZE_NODE_CLASS_VARIABLE(Enum)
  INITIALIZE_NODE_CLASS_VARIABLE(Field)
  INITIALIZE_NODE_CLASS_VARIABLE(FragmentDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(FragmentSpread)
  INITIALIZE_NODE_CLASS_VARIABLE(InlineFragment)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObject)
  INITIALIZE_NODE_CLASS_VARIABLE(ListType)
  INITIALIZE_NODE_CLASS_VARIABLE(NonNullType)
  INITIALIZE_NODE_CLASS_VARIABLE(NullValue)
  INITIALIZE_NODE_CLASS_VARIABLE(OperationDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(TypeName)
  INITIALIZE_NODE_CLASS_VARIABLE(VariableDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(VariableIdentifier)

  INITIALIZE_NODE_CLASS_VARIABLE(ScalarTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(ObjectTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InterfaceTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(UnionTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObjectTypeDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumValueDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(DirectiveDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(DirectiveLocation)
  INITIALIZE_NODE_CLASS_VARIABLE(FieldDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(InputValueDefinition)
  INITIALIZE_NODE_CLASS_VARIABLE(SchemaDefinition)

  INITIALIZE_NODE_CLASS_VARIABLE(ScalarTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(ObjectTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(InterfaceTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(UnionTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(EnumTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(InputObjectTypeExtension)
  INITIALIZE_NODE_CLASS_VARIABLE(SchemaExtension)
}
