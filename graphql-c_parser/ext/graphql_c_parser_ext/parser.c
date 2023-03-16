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


#line 114 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

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
  YYSYMBOL_variable_definitions_opt = 48,  /* variable_definitions_opt  */
  YYSYMBOL_variable_definitions_list = 49, /* variable_definitions_list  */
  YYSYMBOL_variable_definition = 50,       /* variable_definition  */
  YYSYMBOL_default_value_opt = 51,         /* default_value_opt  */
  YYSYMBOL_selection_list = 52,            /* selection_list  */
  YYSYMBOL_selection = 53,                 /* selection  */
  YYSYMBOL_selection_set = 54,             /* selection_set  */
  YYSYMBOL_selection_set_opt = 55,         /* selection_set_opt  */
  YYSYMBOL_field = 56,                     /* field  */
  YYSYMBOL_arguments_opt = 57,             /* arguments_opt  */
  YYSYMBOL_arguments_list = 58,            /* arguments_list  */
  YYSYMBOL_argument = 59,                  /* argument  */
  YYSYMBOL_literal_value = 60,             /* literal_value  */
  YYSYMBOL_input_value = 61,               /* input_value  */
  YYSYMBOL_null_value = 62,                /* null_value  */
  YYSYMBOL_variable = 63,                  /* variable  */
  YYSYMBOL_list_value = 64,                /* list_value  */
  YYSYMBOL_list_value_list = 65,           /* list_value_list  */
  YYSYMBOL_enum_name = 66,                 /* enum_name  */
  YYSYMBOL_enum_value = 67,                /* enum_value  */
  YYSYMBOL_object_value = 68,              /* object_value  */
  YYSYMBOL_object_value_list_opt = 69,     /* object_value_list_opt  */
  YYSYMBOL_object_value_list = 70,         /* object_value_list  */
  YYSYMBOL_object_value_field = 71,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 72,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list_opt = 73, /* object_literal_value_list_opt  */
  YYSYMBOL_object_literal_value_list = 74, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 75, /* object_literal_value_field  */
  YYSYMBOL_directives_list_opt = 76,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 77,           /* directives_list  */
  YYSYMBOL_directive = 78,                 /* directive  */
  YYSYMBOL_name = 79,                      /* name  */
  YYSYMBOL_schema_keyword = 80,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 81,           /* name_without_on  */
  YYSYMBOL_fragment_spread = 82,           /* fragment_spread  */
  YYSYMBOL_inline_fragment = 83,           /* inline_fragment  */
  YYSYMBOL_fragment_definition = 84,       /* fragment_definition  */
  YYSYMBOL_fragment_name_opt = 85,         /* fragment_name_opt  */
  YYSYMBOL_type = 86,                      /* type  */
  YYSYMBOL_nullable_type = 87,             /* nullable_type  */
  YYSYMBOL_type_system_definition = 88,    /* type_system_definition  */
  YYSYMBOL_schema_definition = 89,         /* schema_definition  */
  YYSYMBOL_operation_type_definition_list = 90, /* operation_type_definition_list  */
  YYSYMBOL_operation_type_definition = 91, /* operation_type_definition  */
  YYSYMBOL_type_definition = 92,           /* type_definition  */
  YYSYMBOL_description = 93,               /* description  */
  YYSYMBOL_description_opt = 94,           /* description_opt  */
  YYSYMBOL_scalar_type_definition = 95,    /* scalar_type_definition  */
  YYSYMBOL_object_type_definition = 96,    /* object_type_definition  */
  YYSYMBOL_implements_opt = 97,            /* implements_opt  */
  YYSYMBOL_implements = 98,                /* implements  */
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
  YYSYMBOL_directive_locations = 116       /* directive_locations  */
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
#define YYFINAL  63
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   783

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  77
/* YYNRULES -- Number of rules.  */
#define YYNRULES  166
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  270

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
       0,    92,    92,    94,   112,   113,   116,   117,   121,   122,
     125,   136,   147,   158,   169,   182,   183,   184,   187,   188,
     191,   192,   195,   206,   207,   210,   211,   214,   215,   216,
     219,   222,   223,   226,   237,   250,   251,   254,   255,   258,
     268,   269,   270,   271,   272,   273,   274,   275,   276,   279,
     280,   281,   283,   291,   300,   301,   304,   305,   308,   309,
     310,   311,   312,   313,   315,   323,   324,   333,   334,   337,
     338,   341,   352,   361,   362,   365,   366,   369,   380,   381,
     384,   385,   387,   397,   398,   401,   402,   403,   406,   407,
     408,   409,   410,   411,   412,   413,   414,   417,   418,   419,
     420,   421,   422,   423,   427,   437,   446,   457,   469,   470,
     473,   474,   477,   484,   493,   494,   495,   498,   511,   512,
     517,   523,   524,   525,   526,   527,   528,   530,   532,   534,
     537,   549,   561,   574,   575,   578,   579,   580,   583,   590,
     595,   602,   607,   621,   622,   625,   626,   629,   643,   644,
     647,   648,   649,   652,   666,   673,   678,   691,   704,   716,
     717,   722,   735,   748,   750,   753,   754
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
  "operation_definition", "operation_type", "variable_definitions_opt",
  "variable_definitions_list", "variable_definition", "default_value_opt",
  "selection_list", "selection", "selection_set", "selection_set_opt",
  "field", "arguments_opt", "arguments_list", "argument", "literal_value",
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
  "implements_opt", "implements", "interfaces_list",
  "legacy_interfaces_list", "input_value_definition",
  "input_value_definition_list", "arguments_definitions_opt",
  "field_definition", "field_definition_list_opt", "field_definition_list",
  "interface_type_definition", "union_members", "union_type_definition",
  "enum_type_definition", "enum_value_definition",
  "enum_value_definitions", "input_object_type_definition",
  "directive_definition", "directive_repeatable_opt",
  "directive_locations", YY_NULLPTR
  };
  return yy_sname[yysymbol];
}
#endif

#define YYPACT_NINF (-216)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-151)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     182,  -216,  -216,  -216,   679,  -216,  -216,  -216,  -216,   415,
    -216,  -216,  -216,  -216,  -216,     7,  -216,  -216,  -216,   712,
    -216,    20,  -216,   182,  -216,  -216,  -216,   514,    35,  -216,
    -216,  -216,  -216,  -216,  -216,  -216,     5,  -216,  -216,  -216,
    -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,    41,
     547,  -216,   448,  -216,  -216,    17,  -216,  -216,   712,     9,
      60,  -216,    58,  -216,  -216,    48,    60,    35,    60,    73,
     712,   712,   712,   712,   712,   712,   580,   580,    71,    60,
    -216,  -216,   712,   712,    60,    59,    42,  -216,    -1,  -216,
     712,   -14,  -216,    71,    60,    71,   712,    60,    60,    76,
      60,    76,    60,   580,  -216,    60,    93,    60,   613,  -216,
    -216,    59,   646,  -216,    94,    71,  -216,    95,    24,  -216,
     712,  -216,    15,    96,  -216,  -216,  -216,    71,  -216,    80,
      77,    82,   247,    60,  -216,  -216,    60,    99,    83,    71,
    -216,    71,   481,    60,  -216,  -216,   348,  -216,  -216,   712,
    -216,  -216,    80,  -216,  -216,   580,  -216,    70,    84,    70,
      70,   712,  -216,   107,   712,    58,    58,   712,  -216,  -216,
    -216,  -216,    71,  -216,  -216,  -216,  -216,  -216,   280,   712,
    -216,  -216,  -216,  -216,  -216,   712,  -216,  -216,  -216,  -216,
    -216,  -216,  -216,  -216,  -216,  -216,  -216,  -216,   108,   109,
     712,  -216,    54,  -216,    92,   745,  -216,    26,    34,  -216,
     107,   712,  -216,  -216,  -216,  -216,    98,  -216,  -216,  -216,
     314,   100,   712,  -216,   101,   712,  -216,   116,  -216,   580,
     382,  -216,   117,  -216,  -216,   712,    60,  -216,  -216,  -216,
    -216,   712,  -216,  -216,  -216,  -216,   122,  -216,  -216,   123,
     348,    60,   712,  -216,   580,  -216,   105,  -216,  -216,   348,
     382,  -216,  -216,  -216,   109,   712,  -216,    60,  -216,  -216
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
       0,    96,    94,   101,    98,    97,    95,    91,    92,     0,
      16,    84,    15,    99,    89,    78,   127,    17,   100,    90,
      93,     0,     2,     3,     4,     6,     8,    18,    18,   103,
      83,     9,     7,   114,   115,   129,     0,   121,   122,   123,
     124,   125,   126,   116,    98,    88,    90,   102,   109,     0,
      78,    14,     0,    25,    27,    35,    28,    29,     0,     0,
      79,    80,   148,     1,     5,     0,    78,    18,    78,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,    78,
      13,    26,     0,     0,    78,    35,     0,    81,   128,   132,
       0,     0,    20,     0,    78,     0,     0,    78,    78,   133,
      78,   133,    78,     0,   112,    78,   110,    78,     0,   106,
     104,    35,     0,    37,     0,    31,    82,     0,     0,   118,
       0,   151,   128,     0,    19,    21,    12,     0,    11,   145,
       0,     0,     0,    78,   134,   130,    78,     0,     0,     0,
     111,     0,     0,    78,    36,    38,    65,    32,    34,     0,
     117,   119,   145,   149,   152,     0,    10,   128,   163,   128,
     128,     0,   138,   136,   137,   148,   148,     0,   113,   107,
     105,    30,    31,    44,    40,    59,    58,    41,     0,    67,
      52,    61,    60,    42,    43,     0,    62,    49,    39,    45,
      50,    47,    64,    46,    51,    48,    63,   120,     0,    23,
       0,   143,   128,   164,     0,     0,   159,   128,   128,   138,
     135,     0,   141,   153,   131,   154,   156,    33,    54,    56,
       0,     0,    68,    69,     0,    74,    75,     0,    53,     0,
       0,    22,     0,   146,   144,     0,    78,   157,   160,   161,
     139,     0,    55,    57,    66,    70,     0,    72,    76,     0,
      65,    78,    73,    24,     0,   165,   162,   158,   155,    65,
       0,    49,    71,   147,    23,     0,    77,    78,   166,   142
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -216,  -216,  -216,  -216,   111,  -216,  -216,     8,   -21,  -216,
      44,  -126,    32,   -47,   -77,   -29,  -216,   -73,  -216,    33,
    -215,  -142,  -216,  -216,  -216,  -216,   -58,  -216,  -216,  -216,
    -216,   -74,  -216,  -216,  -216,   -75,    39,  -216,    91,     0,
    -144,     6,  -216,  -216,  -216,  -216,   -71,  -216,  -216,  -216,
    -216,    37,  -216,  -216,     3,  -216,  -216,    51,  -216,    -8,
    -216,  -154,    -4,    11,    38,  -125,  -216,  -216,  -216,  -216,
    -216,   -50,  -216,  -216,  -216,  -216,  -216
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,    21,    22,    23,    24,    25,    26,    47,    66,    91,
      92,   231,    52,    53,   147,   148,    54,    84,   112,   113,
     187,   262,   189,   190,   191,   220,   192,   193,   194,   221,
     222,   223,   195,   224,   225,   226,    59,    60,    61,   104,
      29,    30,    56,    57,    31,    49,   105,   106,    32,    33,
     118,   119,    34,    35,   200,    37,    38,   133,   134,   163,
     164,   201,   202,   158,   121,    89,   122,    39,   216,    40,
      41,   206,   207,    42,    43,   204,   256
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      28,   109,   196,    36,   188,    81,   107,    68,    27,    55,
      48,    69,   116,    70,    58,   253,   126,   124,   128,    62,
      63,    71,    82,    28,    72,    90,    36,    67,  -150,   -88,
      86,    27,   138,    16,   196,   261,   219,    73,   143,    83,
     213,   214,    74,    75,   153,   266,    94,    10,   234,    16,
     156,    12,    55,   150,   234,   237,    79,    65,    85,    17,
      16,   196,   169,   239,   170,    10,    76,    58,    16,    12,
      97,    98,    99,   100,   101,   102,   196,    17,   243,    88,
      96,    83,   111,   114,   199,   233,   196,    90,    16,    78,
     123,   120,   108,   132,   117,    81,   129,   140,   159,   146,
     149,   155,   157,   160,    16,    93,   196,    95,    55,   167,
     211,   168,   114,   229,   203,   196,   196,   235,   110,   230,
     152,   250,   254,   115,   241,   120,   117,   259,   260,   244,
     247,   265,   162,   127,    64,   125,   130,   131,   267,   135,
     142,   137,    55,   217,   139,   145,   141,   236,   245,   197,
     248,    87,   136,   210,   186,   151,   208,   238,   251,     0,
     154,   209,   205,   198,   212,     0,     0,   215,     0,     0,
       0,     0,   165,     0,     0,   166,     0,     0,     0,   227,
       0,     0,   172,   264,     0,   228,   186,     0,     1,     0,
       2,     0,     0,     0,     3,     0,     4,     5,     6,     7,
     232,     8,     0,     9,     0,    10,     0,    11,     0,    12,
     205,   240,    13,   186,    14,    15,    16,    17,    18,    19,
      20,     0,   246,     0,     0,   249,     0,     0,   186,     0,
       0,     0,     0,     0,     0,   255,     0,     0,   186,     0,
       0,   258,     0,     0,     0,     0,     0,     0,     0,     0,
     161,     0,   249,     1,     0,     2,     0,     0,   186,     3,
       0,    44,     5,     6,     7,   268,     8,   186,   186,     0,
      10,     0,    11,     0,    12,   257,     0,    13,     0,    14,
      45,     0,    17,    18,    46,    20,     1,     0,     2,     0,
     263,     0,   173,   174,   175,   176,     6,     7,   177,     8,
     178,   179,     0,    10,   180,   181,   269,    12,   218,     0,
     182,     0,    14,    45,   183,    17,   184,    46,    20,   185,
       1,     0,     2,     0,     0,     0,   173,   174,   175,   176,
       6,     7,   177,     8,   178,   179,     0,    10,   180,   181,
       0,    12,   242,     0,   182,     0,    14,    45,   183,    17,
     184,    46,    20,   185,     1,     0,     2,     0,     0,     0,
     173,   174,   175,   176,     6,     7,   177,     8,   178,   179,
       0,    10,   180,   181,     0,    12,     0,     0,   182,     0,
      14,    45,   183,    17,   184,    46,    20,   185,     1,     0,
       2,     0,     0,     0,   173,   174,   175,   176,     6,     7,
     177,     8,   178,   252,     0,    10,   180,   181,     0,    12,
       0,     0,   182,     0,    14,    45,   183,    17,   184,    46,
      20,     1,     0,     2,    50,     0,     0,     3,     0,    44,
       5,     6,     7,     0,     8,     0,     0,     0,    10,     0,
      11,     0,    12,     0,    51,    13,     0,    14,    45,     0,
      17,    18,    46,    20,     1,     0,     2,    50,     0,     0,
       3,     0,    44,     5,     6,     7,     0,     8,     0,     0,
       0,    10,     0,    11,     0,    12,     0,    80,    13,     0,
      14,    45,     0,    17,    18,    46,    20,     1,     0,     2,
      50,     0,     0,     3,     0,    44,     5,     6,     7,     0,
       8,     0,     0,     0,    10,     0,    11,     0,    12,     0,
     171,    13,     0,    14,    45,     0,    17,    18,    46,    20,
       1,     0,     2,     0,     0,     0,     3,     0,    44,     5,
       6,     7,     0,     8,     0,     0,    65,    10,     0,    11,
       0,    12,     0,     0,    13,     0,    14,    45,     0,    17,
      18,    46,    20,     1,    58,     2,     0,     0,     0,     3,
       0,    44,     5,     6,     7,     0,     8,     0,     0,     0,
      10,     0,    77,     0,    12,     0,     0,    13,     0,    14,
      45,     0,    17,    18,    46,    20,     1,     0,     2,     0,
       0,     0,     3,     0,    44,     5,     6,     7,     0,     8,
     103,     0,     0,    10,     0,    11,     0,    12,     0,     0,
      13,     0,    14,    45,     0,    17,    18,    46,    20,     1,
       0,     2,    50,     0,     0,     3,     0,    44,     5,     6,
       7,     0,     8,     0,     0,     0,    10,     0,    11,     0,
      12,     0,     0,    13,     0,    14,    45,     0,    17,    18,
      46,    20,     1,     0,     2,     0,     0,     0,     3,     0,
      44,     5,     6,     7,     0,     8,     0,     0,     0,    10,
       0,    11,     0,    12,     0,     0,    13,   144,    14,    45,
       0,    17,    18,    46,    20,     1,     0,     2,     0,     0,
       0,     3,     0,    44,     5,     6,     7,     0,     8,     0,
       0,     0,    10,     0,  -108,     0,    12,     0,     0,    13,
       0,    14,    45,     0,    17,    18,    46,    20,     1,     0,
       2,     0,     0,     0,     3,     0,    44,     5,     6,     7,
       0,     8,     0,     0,     0,    10,     0,    11,     0,    12,
       0,     0,    13,     0,    14,    45,     0,    17,    18,    46,
      20,     1,     0,     2,     0,     0,     0,     0,     0,   175,
     176,     6,     7,     0,     8,     0,     0,     0,    10,     0,
     181,     0,    12,     0,     0,   182,     0,    14,    45,     0,
      17,     0,    46,    20
};

static const yytype_int16 yycheck[] =
{
       0,    78,   146,     0,   146,    52,    77,    28,     0,     9,
       4,     6,    85,     8,     7,   230,    93,    31,    95,    19,
       0,    16,     5,    23,    19,    39,    23,    27,    29,    22,
      21,    23,   103,    34,   178,   250,   178,    32,   111,    22,
     165,   166,    37,    38,    29,   260,    67,    23,   202,    34,
     127,    27,    52,    29,   208,    29,    50,    22,    58,    35,
      34,   205,   139,    29,   141,    23,    25,     7,    34,    27,
      70,    71,    72,    73,    74,    75,   220,    35,   220,    21,
       7,    22,    82,    83,   155,    31,   230,    39,    34,    50,
      90,    88,    21,    17,    86,   142,    96,     4,    21,     5,
       5,     5,    22,    21,    34,    66,   250,    68,   108,    10,
       3,    28,   112,     5,    30,   259,   260,    25,    79,    10,
     120,     5,     5,    84,    26,   122,   118,     5,     5,    29,
      29,    26,   132,    94,    23,    91,    97,    98,   264,   100,
     108,   102,   142,   172,   105,   112,   107,   205,   222,   149,
     225,    60,   101,   161,   146,   118,   160,   207,   229,    -1,
     122,   161,   159,   152,   164,    -1,    -1,   167,    -1,    -1,
      -1,    -1,   133,    -1,    -1,   136,    -1,    -1,    -1,   179,
      -1,    -1,   143,   254,    -1,   185,   178,    -1,     6,    -1,
       8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,
     200,    19,    -1,    21,    -1,    23,    -1,    25,    -1,    27,
     207,   211,    30,   205,    32,    33,    34,    35,    36,    37,
      38,    -1,   222,    -1,    -1,   225,    -1,    -1,   220,    -1,
      -1,    -1,    -1,    -1,    -1,   235,    -1,    -1,   230,    -1,
      -1,   241,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
       3,    -1,   252,     6,    -1,     8,    -1,    -1,   250,    12,
      -1,    14,    15,    16,    17,   265,    19,   259,   260,    -1,
      23,    -1,    25,    -1,    27,   236,    -1,    30,    -1,    32,
      33,    -1,    35,    36,    37,    38,     6,    -1,     8,    -1,
     251,    -1,    12,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    -1,    23,    24,    25,   267,    27,    28,    -1,
      30,    -1,    32,    33,    34,    35,    36,    37,    38,    39,
       6,    -1,     8,    -1,    -1,    -1,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    -1,    23,    24,    25,
      -1,    27,    28,    -1,    30,    -1,    32,    33,    34,    35,
      36,    37,    38,    39,     6,    -1,     8,    -1,    -1,    -1,
      12,    13,    14,    15,    16,    17,    18,    19,    20,    21,
      -1,    23,    24,    25,    -1,    27,    -1,    -1,    30,    -1,
      32,    33,    34,    35,    36,    37,    38,    39,     6,    -1,
       8,    -1,    -1,    -1,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    -1,    23,    24,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    34,    35,    36,    37,
      38,     6,    -1,     8,     9,    -1,    -1,    12,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,
      25,    -1,    27,    -1,    29,    30,    -1,    32,    33,    -1,
      35,    36,    37,    38,     6,    -1,     8,     9,    -1,    -1,
      12,    -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,
      -1,    23,    -1,    25,    -1,    27,    -1,    29,    30,    -1,
      32,    33,    -1,    35,    36,    37,    38,     6,    -1,     8,
       9,    -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,
      19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,
      29,    30,    -1,    32,    33,    -1,    35,    36,    37,    38,
       6,    -1,     8,    -1,    -1,    -1,    12,    -1,    14,    15,
      16,    17,    -1,    19,    -1,    -1,    22,    23,    -1,    25,
      -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,    35,
      36,    37,    38,     6,     7,     8,    -1,    -1,    -1,    12,
      -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,
      23,    -1,    25,    -1,    27,    -1,    -1,    30,    -1,    32,
      33,    -1,    35,    36,    37,    38,     6,    -1,     8,    -1,
      -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,    19,
      20,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,    -1,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,     9,    -1,    -1,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,
      27,    -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,
      37,    38,     6,    -1,     8,    -1,    -1,    -1,    12,    -1,
      14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,
      -1,    25,    -1,    27,    -1,    -1,    30,    31,    32,    33,
      -1,    35,    36,    37,    38,     6,    -1,     8,    -1,    -1,
      -1,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    -1,    25,    -1,    27,    -1,    -1,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38,     6,    -1,
       8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,
      -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,    37,
      38,     6,    -1,     8,    -1,    -1,    -1,    -1,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,
      25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,
      35,    -1,    37,    38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,     6,     8,    12,    14,    15,    16,    17,    19,    21,
      23,    25,    27,    30,    32,    33,    34,    35,    36,    37,
      38,    41,    42,    43,    44,    45,    46,    47,    79,    80,
      81,    84,    88,    89,    92,    93,    94,    95,    96,   107,
     109,   110,   113,   114,    14,    33,    37,    47,    81,    85,
       9,    29,    52,    53,    56,    79,    82,    83,     7,    76,
      77,    78,    79,     0,    44,    22,    48,    79,    48,     6,
       8,    16,    19,    32,    37,    38,    25,    25,    76,    81,
      29,    53,     5,    22,    57,    79,    21,    78,    21,   105,
      39,    49,    50,    76,    48,    76,     7,    79,    79,    79,
      79,    79,    79,    20,    79,    86,    87,    86,    21,    54,
      76,    79,    58,    59,    79,    76,    57,    47,    90,    91,
      94,   104,   106,    79,    31,    50,    54,    76,    54,    79,
      76,    76,    17,    97,    98,    76,    97,    76,    86,    76,
       4,    76,    52,    57,    31,    59,     5,    54,    55,     5,
      29,    91,    79,    29,   104,     5,    54,    22,   103,    21,
      21,     3,    79,    99,   100,    76,    76,    10,    28,    54,
      54,    29,    76,    12,    13,    14,    15,    18,    20,    21,
      24,    25,    30,    34,    36,    39,    47,    60,    61,    62,
      63,    64,    66,    67,    68,    72,    80,    79,   103,    86,
      94,   101,   102,    30,   115,    94,   111,   112,   102,    79,
      99,     3,    79,   105,   105,    79,   108,    55,    28,    61,
      65,    69,    70,    71,    73,    74,    75,    79,    79,     5,
      10,    51,    79,    31,   101,    25,    66,    29,   111,    29,
      79,    26,    28,    61,    29,    71,    79,    29,    75,    79,
       5,    86,    21,    60,     5,    79,   116,    76,    79,     5,
       5,    60,    61,    76,    86,    26,    60,    51,    79,    76
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    44,    44,    45,    45,
      46,    46,    46,    46,    46,    47,    47,    47,    48,    48,
      49,    49,    50,    51,    51,    52,    52,    53,    53,    53,
      54,    55,    55,    56,    56,    57,    57,    58,    58,    59,
      60,    60,    60,    60,    60,    60,    60,    60,    60,    61,
      61,    61,    62,    63,    64,    64,    65,    65,    66,    66,
      66,    66,    66,    66,    67,    68,    68,    69,    69,    70,
      70,    71,    72,    73,    73,    74,    74,    75,    76,    76,
      77,    77,    78,    79,    79,    47,    47,    47,    80,    80,
      80,    80,    80,    80,    80,    80,    80,    81,    81,    81,
      81,    81,    81,    81,    82,    83,    83,    84,    85,    85,
      86,    86,    87,    87,    88,    88,    88,    89,    90,    90,
      91,    92,    92,    92,    92,    92,    92,    93,    94,    94,
      95,    96,    96,    97,    97,    98,    98,    98,    99,    99,
     100,   100,   101,   102,   102,   103,   103,   104,   105,   105,
     106,   106,   106,   107,   108,   108,   109,   110,   111,   112,
     112,   113,   114,   115,   115,   116,   116
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     1,     2,     1,     1,     1,     1,
       5,     4,     4,     3,     2,     1,     1,     1,     0,     3,
       1,     2,     5,     0,     2,     1,     2,     1,     1,     1,
       3,     0,     1,     6,     4,     0,     3,     1,     2,     3,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     2,     2,     3,     1,     2,     1,     1,
       1,     1,     1,     1,     1,     0,     3,     0,     1,     1,
       2,     3,     3,     0,     1,     1,     2,     3,     0,     1,
       1,     2,     3,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     3,     5,     3,     6,     0,     1,
       1,     2,     1,     3,     1,     1,     1,     5,     1,     2,
       3,     1,     1,     1,     1,     1,     1,     1,     0,     1,
       4,     6,     3,     0,     1,     3,     2,     2,     1,     3,
       1,     2,     6,     1,     2,     0,     3,     6,     0,     3,
       0,     1,     2,     6,     1,     3,     6,     7,     3,     1,
       2,     7,     8,     0,     1,     1,     3
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
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { rb_ivar_set(parser, rb_intern("@result"), yyvsp[0]); }
#line 1869 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 3: /* document: definitions_list  */
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 1890 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 4: /* definitions_list: definition  */
#line 112 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1896 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 5: /* definitions_list: definitions_list definition  */
#line 113 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 1902 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 10: /* operation_definition: operation_type name variable_definitions_opt directives_list_opt selection_set  */
#line 125 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                     {
        yyval = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 1918 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 11: /* operation_definition: name variable_definitions_opt directives_list_opt selection_set  */
#line 136 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                      {
        yyval = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          r_string_query,
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 1934 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 12: /* operation_definition: operation_type variable_definitions_opt directives_list_opt selection_set  */
#line 147 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                {
        yyval = rb_funcall(GraphQL_Language_Nodes_OperationDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-3], 3),
          Qnil,
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 1950 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 13: /* operation_definition: LCURLY selection_list RCURLY  */
#line 158 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 1966 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 14: /* operation_definition: LCURLY RCURLY  */
#line 169 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 1982 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 18: /* variable_definitions_opt: %empty  */
#line 187 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = GraphQL_Language_Nodes_NONE; }
#line 1988 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 19: /* variable_definitions_opt: LPAREN variable_definitions_list RPAREN  */
#line 188 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = yyvsp[-1]; }
#line 1994 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 20: /* variable_definitions_list: variable_definition  */
#line 191 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2000 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 21: /* variable_definitions_list: variable_definitions_list variable_definition  */
#line 192 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 2006 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 22: /* variable_definition: VAR_SIGN name COLON type default_value_opt  */
#line 195 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_VariableDefinition, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2020 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 23: /* default_value_opt: %empty  */
#line 206 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = Qnil; }
#line 2026 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 24: /* default_value_opt: EQUALS literal_value  */
#line 207 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = yyvsp[0]; }
#line 2032 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 25: /* selection_list: selection  */
#line 210 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2038 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 26: /* selection_list: selection_list selection  */
#line 211 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2044 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 30: /* selection_set: LCURLY selection_list RCURLY  */
#line 219 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   { yyval = yyvsp[-1]; }
#line 2050 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 31: /* selection_set_opt: %empty  */
#line 222 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = rb_ary_new(); }
#line 2056 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 33: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 226 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2072 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 34: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 237 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2088 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 35: /* arguments_opt: %empty  */
#line 250 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = Qnil; }
#line 2094 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 36: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 251 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = yyvsp[-1]; }
#line 2100 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 37: /* arguments_list: argument  */
#line 254 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2106 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 38: /* arguments_list: arguments_list argument  */
#line 255 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { rb_ary_push(yyval, yyvsp[0]); }
#line 2112 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 39: /* argument: name COLON input_value  */
#line 258 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2125 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 40: /* literal_value: FLOAT  */
#line 268 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_f"), 0); }
#line 2131 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 41: /* literal_value: INT  */
#line 269 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_i"), 0); }
#line 2137 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 42: /* literal_value: STRING  */
#line 270 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2143 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 43: /* literal_value: TRUE_LITERAL  */
#line 271 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qtrue; }
#line 2149 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 44: /* literal_value: FALSE_LITERAL  */
#line 272 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qfalse; }
#line 2155 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 52: /* null_value: NULL_LITERAL  */
#line 283 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                           {
    yyval = rb_funcall(GraphQL_Language_Nodes_NullValue, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2167 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 53: /* variable: VAR_SIGN name  */
#line 291 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          {
    yyval = rb_funcall(GraphQL_Language_Nodes_VariableIdentifier, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[-1], 1),
      rb_ary_entry(yyvsp[-1], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2179 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 54: /* list_value: LBRACKET RBRACKET  */
#line 300 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2185 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 55: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 301 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[-1]; }
#line 2191 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 56: /* list_value_list: input_value  */
#line 304 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2197 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 57: /* list_value_list: list_value_list input_value  */
#line 305 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 2203 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 64: /* enum_value: enum_name  */
#line 315 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        {
    yyval = rb_funcall(GraphQL_Language_Nodes_Enum, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2215 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 66: /* object_value: LCURLY object_value_list_opt RCURLY  */
#line 324 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          {
      yyval = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
        rb_ary_entry(yyvsp[-2], 1),
        rb_ary_entry(yyvsp[-2], 2),
        yyvsp[-1]
      );
    }
#line 2227 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 67: /* object_value_list_opt: %empty  */
#line 333 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2233 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 69: /* object_value_list: object_value_field  */
#line 337 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2239 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 70: /* object_value_list: object_value_list object_value_field  */
#line 338 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2245 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 71: /* object_value_field: name COLON input_value  */
#line 341 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2258 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 72: /* object_literal_value: LCURLY object_literal_value_list_opt RCURLY  */
#line 352 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          yyvsp[-1]
        );
      }
#line 2270 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 73: /* object_literal_value_list_opt: %empty  */
#line 361 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2276 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 75: /* object_literal_value_list: object_literal_value_field  */
#line 365 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2282 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 76: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 366 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2288 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 77: /* object_literal_value_field: name COLON literal_value  */
#line 369 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2301 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 78: /* directives_list_opt: %empty  */
#line 380 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = GraphQL_Language_Nodes_NONE; }
#line 2307 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 80: /* directives_list: directive  */
#line 384 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2313 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 81: /* directives_list: directives_list directive  */
#line 385 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2319 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 82: /* directive: DIR_SIGN name arguments_opt  */
#line 387 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                         {
    yyval = rb_funcall(GraphQL_Language_Nodes_Directive, rb_intern("from_a"), 4,
      rb_ary_entry(yyvsp[-2], 1),
      rb_ary_entry(yyvsp[-2], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2332 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 104: /* fragment_spread: ELLIPSIS name_without_on directives_list_opt  */
#line 427 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   {
        yyval = rb_funcall(GraphQL_Language_Nodes_FragmentSpread, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0]
        );
      }
#line 2345 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 105: /* inline_fragment: ELLIPSIS ON type directives_list_opt selection_set  */
#line 437 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         {
        yyval = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2359 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 106: /* inline_fragment: ELLIPSIS directives_list_opt selection_set  */
#line 446 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2373 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 107: /* fragment_definition: FRAGMENT fragment_name_opt ON type directives_list_opt selection_set  */
#line 457 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2388 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 108: /* fragment_name_opt: %empty  */
#line 469 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2394 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 109: /* fragment_name_opt: name_without_on  */
#line 470 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2400 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 111: /* type: nullable_type BANG  */
#line 474 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_funcall(GraphQL_Language_Nodes_NonNullType, rb_intern("from_a"), 3, rb_funcall(yyvsp[-1], rb_intern("line"), 0), rb_funcall(yyvsp[-1], rb_intern("col"), 0), yyvsp[-1]); }
#line 2406 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 112: /* nullable_type: name  */
#line 477 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2418 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 113: /* nullable_type: LBRACKET type RBRACKET  */
#line 484 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_ListType, rb_intern("from_a"), 3,
          rb_funcall(yyvsp[-1], rb_intern("line"), 0),
          rb_funcall(yyvsp[-1], rb_intern("col"), 0),
          yyvsp[-1]
        );
      }
#line 2430 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 117: /* schema_definition: SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 498 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                              {
        yyval = rb_funcall(GraphQL_Language_Nodes_SchemaDefinition, rb_intern("from_a"), 6,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          yyvsp[-3],
          // TODO use static strings:
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("subscription"))
        );
      }
#line 2446 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 119: /* operation_type_definition_list: operation_type_definition_list operation_type_definition  */
#line 512 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      rb_funcall(yyval, rb_intern("merge!"), 1, yyvsp[-1]);
    }
#line 2454 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 120: /* operation_type_definition: operation_type COLON name  */
#line 517 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_hash_new();
        rb_hash_aset(yyval, rb_ary_entry(yyvsp[-2], 3), rb_ary_entry(yyvsp[0], 3));
      }
#line 2463 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 130: /* scalar_type_definition: description_opt SCALAR name directives_list_opt  */
#line 537 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2478 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 131: /* object_type_definition: description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 549 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                     {
        yyval = rb_funcall(GraphQL_Language_Nodes_ObjectTypeDefinition, rb_intern("from_a"), 7,
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
#line 2495 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 132: /* object_type_definition: TYPE_LITERAL name field_definition_list_opt  */
#line 561 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
        yyval = rb_funcall(GraphQL_Language_Nodes_ObjectTypeDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          Qnil,
          Qnil,
          Qnil,
          yyvsp[0]
        );
      }
#line 2511 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 133: /* implements_opt: %empty  */
#line 574 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2517 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 135: /* implements: IMPLEMENTS AMP interfaces_list  */
#line 578 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                     { yyval = yyvsp[0]; }
#line 2523 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 136: /* implements: IMPLEMENTS interfaces_list  */
#line 579 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                 { yyval = yyvsp[0]; }
#line 2529 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 137: /* implements: IMPLEMENTS legacy_interfaces_list  */
#line 580 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[0]; }
#line 2535 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 138: /* interfaces_list: name  */
#line 583 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        yyval = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2547 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 139: /* interfaces_list: interfaces_list AMP name  */
#line 590 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
      rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
    }
#line 2555 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 140: /* legacy_interfaces_list: name  */
#line 595 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        yyval = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2567 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 141: /* legacy_interfaces_list: legacy_interfaces_list name  */
#line 602 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  {
      rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
    }
#line 2575 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 142: /* input_value_definition: description_opt name COLON type default_value_opt directives_list_opt  */
#line 607 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                            {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputValueDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          Qnil,
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2592 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 143: /* input_value_definition_list: input_value_definition  */
#line 621 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2598 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 144: /* input_value_definition_list: input_value_definition_list input_value_definition  */
#line 622 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { rb_ary_push(yyval, yyvsp[-1]); }
#line 2604 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 145: /* arguments_definitions_opt: %empty  */
#line 625 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2610 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 146: /* arguments_definitions_opt: LPAREN input_value_definition_list RPAREN  */
#line 626 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = yyvsp[-1]; }
#line 2616 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 147: /* field_definition: description_opt name arguments_definitions_opt COLON type directives_list_opt  */
#line 629 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                    {
        yyval = rb_funcall(GraphQL_Language_Nodes_FieldDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          Qnil,
          Qnil,
          Qnil,
          Qnil
        );
      }
#line 2633 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 148: /* field_definition_list_opt: %empty  */
#line 643 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2639 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 149: /* field_definition_list_opt: LCURLY field_definition_list RCURLY  */
#line 644 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          { yyval = yyvsp[-1]; }
#line 2645 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 150: /* field_definition_list: %empty  */
#line 647 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2651 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 151: /* field_definition_list: field_definition  */
#line 648 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2657 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 152: /* field_definition_list: field_definition_list field_definition  */
#line 649 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { rb_ary_push(yyval, yyvsp[0]); }
#line 2663 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 153: /* interface_type_definition: description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 652 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2680 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 154: /* union_members: name  */
#line 666 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        yyval = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2692 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 155: /* union_members: union_members PIPE name  */
#line 673 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              {
        rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
      }
#line 2700 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 156: /* union_type_definition: description_opt UNION name directives_list_opt EQUALS union_members  */
#line 678 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                          {
        yyval = rb_funcall(GraphQL_Language_Nodes_UnionTypeDefinition, rb_intern("from_a"),  6,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-2],
          yyvsp[-1]
        );
      }
#line 2716 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 157: /* enum_type_definition: description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 691 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = rb_funcall(GraphQL_Language_Nodes_EnumTypeDefinition, rb_intern("from_a"),  6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-2]
        );
      }
#line 2732 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 158: /* enum_value_definition: description_opt enum_name directives_list_opt  */
#line 704 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2747 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 159: /* enum_value_definitions: enum_value_definition  */
#line 716 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2753 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 160: /* enum_value_definitions: enum_value_definitions enum_value_definition  */
#line 717 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   {
      rb_ary_push(yyval, yyvsp[0]);
     }
#line 2761 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 161: /* input_object_type_definition: description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 722 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2777 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 162: /* directive_definition: description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations  */
#line 735 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                                        {
        yyval = rb_funcall(GraphQL_Language_Nodes_DirectiveDefinition, rb_intern("from_a"), 7,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-7]) ? rb_ary_entry(yyvsp[-7], 3) : Qnil),
          (RB_TEST(yyvsp[-2]) ? Qtrue : Qfalse), // repeatable
          yyvsp[-3],
          yyvsp[0]
        );
      }
#line 2794 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 165: /* directive_locations: name  */
#line 753 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2800 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 166: /* directive_locations: directive_locations PIPE name  */
#line 754 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2806 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;


#line 2810 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

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

#line 756 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"


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
  VALUE next_token_idx = rb_ivar_get(parser, rb_intern("@next_token_index"));
  int this_token_idx = FIX2INT(next_token_idx) - 1;
  VALUE tokens = rb_ivar_get(parser, rb_intern("@tokens"));
  VALUE this_token = rb_ary_entry(tokens, this_token_idx);
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE cParseError = rb_const_get_at(mGraphQL, rb_intern("ParseError"));
  VALUE exception = rb_funcall(
      cParseError, rb_intern("new"), 4,
      rb_str_new_cstr(msg),
      rb_ary_entry(this_token, 1),
      rb_ary_entry(this_token, 2),
      Qnil // TODO pass the whole query string from the parser object
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
}
