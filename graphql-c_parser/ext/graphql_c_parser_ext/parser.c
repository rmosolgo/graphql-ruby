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
  YYSYMBOL_executable_definition = 44,     /* executable_definition  */
  YYSYMBOL_executable_definitions = 45,    /* executable_definitions  */
  YYSYMBOL_type_system_definitions = 46,   /* type_system_definitions  */
  YYSYMBOL_operation_definition = 47,      /* operation_definition  */
  YYSYMBOL_operation_type = 48,            /* operation_type  */
  YYSYMBOL_operation_name_opt = 49,        /* operation_name_opt  */
  YYSYMBOL_variable_definitions_opt = 50,  /* variable_definitions_opt  */
  YYSYMBOL_variable_definitions_list = 51, /* variable_definitions_list  */
  YYSYMBOL_variable_definition = 52,       /* variable_definition  */
  YYSYMBOL_default_value_opt = 53,         /* default_value_opt  */
  YYSYMBOL_selection_list = 54,            /* selection_list  */
  YYSYMBOL_selection = 55,                 /* selection  */
  YYSYMBOL_selection_set = 56,             /* selection_set  */
  YYSYMBOL_selection_set_opt = 57,         /* selection_set_opt  */
  YYSYMBOL_field = 58,                     /* field  */
  YYSYMBOL_arguments_opt = 59,             /* arguments_opt  */
  YYSYMBOL_arguments_list = 60,            /* arguments_list  */
  YYSYMBOL_argument = 61,                  /* argument  */
  YYSYMBOL_literal_value = 62,             /* literal_value  */
  YYSYMBOL_input_value = 63,               /* input_value  */
  YYSYMBOL_null_value = 64,                /* null_value  */
  YYSYMBOL_variable = 65,                  /* variable  */
  YYSYMBOL_list_value = 66,                /* list_value  */
  YYSYMBOL_list_value_list = 67,           /* list_value_list  */
  YYSYMBOL_enum_name = 68,                 /* enum_name  */
  YYSYMBOL_enum_value = 69,                /* enum_value  */
  YYSYMBOL_object_value = 70,              /* object_value  */
  YYSYMBOL_object_value_list_opt = 71,     /* object_value_list_opt  */
  YYSYMBOL_object_value_list = 72,         /* object_value_list  */
  YYSYMBOL_object_value_field = 73,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 74,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list_opt = 75, /* object_literal_value_list_opt  */
  YYSYMBOL_object_literal_value_list = 76, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 77, /* object_literal_value_field  */
  YYSYMBOL_directives_list_opt = 78,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 79,           /* directives_list  */
  YYSYMBOL_directive = 80,                 /* directive  */
  YYSYMBOL_name = 81,                      /* name  */
  YYSYMBOL_schema_keyword = 82,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 83,           /* name_without_on  */
  YYSYMBOL_fragment_spread = 84,           /* fragment_spread  */
  YYSYMBOL_inline_fragment = 85,           /* inline_fragment  */
  YYSYMBOL_fragment_definition = 86,       /* fragment_definition  */
  YYSYMBOL_fragment_name_opt = 87,         /* fragment_name_opt  */
  YYSYMBOL_type = 88,                      /* type  */
  YYSYMBOL_nullable_type = 89,             /* nullable_type  */
  YYSYMBOL_type_system_definition = 90,    /* type_system_definition  */
  YYSYMBOL_schema_definition = 91,         /* schema_definition  */
  YYSYMBOL_operation_type_definition_list = 92, /* operation_type_definition_list  */
  YYSYMBOL_operation_type_definition = 93, /* operation_type_definition  */
  YYSYMBOL_type_definition = 94,           /* type_definition  */
  YYSYMBOL_description = 95,               /* description  */
  YYSYMBOL_description_opt = 96,           /* description_opt  */
  YYSYMBOL_scalar_type_definition = 97,    /* scalar_type_definition  */
  YYSYMBOL_object_type_definition = 98,    /* object_type_definition  */
  YYSYMBOL_implements_opt = 99,            /* implements_opt  */
  YYSYMBOL_interfaces_list = 100,          /* interfaces_list  */
  YYSYMBOL_legacy_interfaces_list = 101,   /* legacy_interfaces_list  */
  YYSYMBOL_input_value_definition = 102,   /* input_value_definition  */
  YYSYMBOL_input_value_definition_list = 103, /* input_value_definition_list  */
  YYSYMBOL_arguments_definitions_opt = 104, /* arguments_definitions_opt  */
  YYSYMBOL_field_definition = 105,         /* field_definition  */
  YYSYMBOL_field_definition_list_opt = 106, /* field_definition_list_opt  */
  YYSYMBOL_field_definition_list = 107,    /* field_definition_list  */
  YYSYMBOL_interface_type_definition = 108, /* interface_type_definition  */
  YYSYMBOL_union_members = 109,            /* union_members  */
  YYSYMBOL_union_type_definition = 110,    /* union_type_definition  */
  YYSYMBOL_enum_type_definition = 111,     /* enum_type_definition  */
  YYSYMBOL_enum_value_definition = 112,    /* enum_value_definition  */
  YYSYMBOL_enum_value_definitions = 113,   /* enum_value_definitions  */
  YYSYMBOL_input_object_type_definition = 114, /* input_object_type_definition  */
  YYSYMBOL_directive_definition = 115,     /* directive_definition  */
  YYSYMBOL_directive_repeatable_opt = 116, /* directive_repeatable_opt  */
  YYSYMBOL_directive_locations = 117       /* directive_locations  */
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
#define YYFINAL  61
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   755

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  78
/* YYNRULES -- Number of rules.  */
#define YYNRULES  164
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  263

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
       0,    92,    92,    94,   112,   113,   114,   117,   118,   121,
     122,   125,   126,   130,   141,   152,   165,   166,   167,   170,
     171,   174,   175,   178,   179,   182,   193,   194,   197,   198,
     201,   202,   203,   206,   209,   210,   213,   224,   237,   238,
     241,   242,   245,   255,   256,   257,   258,   259,   260,   261,
     262,   263,   266,   267,   268,   270,   278,   287,   288,   291,
     292,   295,   296,   297,   298,   299,   300,   302,   310,   311,
     320,   321,   324,   325,   328,   339,   348,   349,   352,   353,
     356,   367,   368,   371,   372,   374,   384,   385,   388,   389,
     390,   391,   392,   393,   394,   395,   396,   399,   400,   401,
     402,   403,   404,   405,   409,   419,   428,   439,   451,   452,
     455,   456,   459,   466,   475,   476,   477,   480,   493,   494,
     499,   505,   506,   507,   508,   509,   510,   512,   515,   516,
     519,   531,   545,   546,   547,   548,   551,   559,   565,   573,
     578,   592,   593,   596,   597,   600,   614,   615,   618,   619,
     620,   623,   637,   645,   650,   663,   676,   688,   689,   692,
     705,   718,   720,   723,   724
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
  "document", "definitions_list", "executable_definition",
  "executable_definitions", "type_system_definitions",
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
  "directive_locations", YY_NULLPTR
  };
  return yy_sname[yysymbol];
}
#endif

#define YYPACT_NINF (-165)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-149)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     143,   684,   420,  -165,  -165,    27,  -165,  -165,    38,  -165,
    -165,  -165,    -6,    11,  -165,   651,  -165,  -165,  -165,  -165,
    -165,   165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,
    -165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,
    -165,  -165,  -165,  -165,  -165,  -165,    15,   519,  -165,  -165,
     453,  -165,  -165,     4,  -165,  -165,  -165,   651,    23,    27,
    -165,  -165,  -165,  -165,   172,    40,  -165,    56,   651,   651,
     651,   651,   651,   651,   552,   552,    60,    27,  -165,  -165,
     651,   651,    27,    65,    16,  -165,    52,    27,   651,    27,
      27,    75,    27,    75,    27,   552,  -165,    27,    89,    27,
     585,  -165,  -165,    65,   618,  -165,    90,    60,  -165,    91,
      -7,  -165,   651,   -12,  -165,    60,    72,    76,    78,   252,
      27,  -165,    27,    93,    73,    60,  -165,    60,   486,    27,
    -165,  -165,   353,  -165,  -165,   651,  -165,  -165,    95,  -165,
    -165,  -165,    70,    77,    70,    70,   651,   121,   102,   651,
      85,    85,   651,  -165,  -165,  -165,  -165,    60,  -165,  -165,
    -165,  -165,  -165,   285,   651,  -165,  -165,  -165,  -165,  -165,
     651,  -165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,  -165,
    -165,  -165,  -165,   552,   651,  -165,    54,  -165,    87,   717,
    -165,     2,    12,  -165,   102,   651,  -165,    24,  -165,  -165,
    -165,    88,  -165,  -165,  -165,   319,    84,   651,  -165,    86,
     651,  -165,   113,  -165,   112,   118,  -165,  -165,   651,    27,
    -165,  -165,  -165,  -165,   651,  -165,    31,   651,  -165,  -165,
    -165,  -165,   120,  -165,  -165,   122,   353,   387,  -165,   552,
    -165,   104,  -165,    72,  -165,  -165,  -165,   353,   387,  -165,
    -165,   651,  -165,   112,   651,   126,  -165,    27,  -165,   552,
    -165,    27,  -165
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
     128,   108,     0,    17,    16,    81,   127,    18,     0,     2,
       3,     9,     5,   128,     7,    19,     8,    11,   114,   115,
     129,     0,   121,   122,   123,   124,   125,   126,   116,    96,
      94,   101,    98,    97,    95,    91,    92,    99,    89,    88,
     100,    90,    93,   102,   103,   109,     0,    81,    87,    15,
       0,    28,    30,    38,    86,    31,    32,     0,     0,    82,
      83,     1,    10,    12,     0,    21,    20,     0,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    81,    14,    29,
       0,     0,    81,    38,     0,    84,     0,    81,     0,    81,
      81,   132,    81,   132,    81,     0,   112,    81,   110,    81,
       0,   106,   104,    38,     0,    40,     0,    34,    85,     0,
       0,   118,     0,     0,    23,     0,   143,     0,     0,     0,
      81,   130,    81,     0,     0,     0,   111,     0,     0,    81,
      39,    41,    68,    35,    37,     0,   117,   119,     0,    22,
      24,    13,   128,   161,   128,   128,     0,   138,   134,   135,
     146,   146,     0,   113,   107,   105,    33,    34,    47,    43,
      62,    61,    44,     0,    70,    55,    64,    63,    45,    46,
       0,    65,    52,    42,    48,    53,    50,    67,    49,    54,
      51,    66,   120,     0,     0,   141,   128,   162,     0,     0,
     157,   128,   128,   136,   133,     0,   139,   128,   151,   131,
     152,   154,    36,    57,    59,     0,     0,    71,    72,     0,
      77,    78,     0,    56,    26,     0,   144,   142,     0,    81,
     155,   158,   159,   137,     0,   149,   128,     0,    58,    60,
      69,    73,     0,    75,    79,     0,    68,     0,    25,     0,
     163,   160,   156,   143,   147,   150,   153,    68,     0,    52,
      74,    76,    27,    26,     0,     0,    80,    81,   164,     0,
     140,    81,   145
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -165,  -165,  -165,  -165,   123,  -165,  -165,  -165,     6,  -165,
    -165,  -165,    19,  -119,    36,   -45,   -51,   -18,  -165,   -71,
    -165,    37,  -164,  -130,  -165,  -165,  -165,  -165,   -43,  -165,
    -165,  -165,  -165,   -59,  -165,  -165,  -165,   -61,   -40,  -165,
      92,    -2,  -128,     9,  -165,  -165,  -165,  -165,   -72,  -165,
    -165,  -165,  -165,    42,   141,  -165,     1,  -165,  -165,    63,
      14,  -165,  -162,    18,   -82,   -54,    32,  -165,  -165,  -165,
    -165,  -165,   -26,  -165,  -165,  -165,  -165,  -165
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_uint8 yydefgoto[] =
{
       0,     8,     9,    10,    11,    12,    13,    14,    43,    65,
      87,   113,   114,   238,    50,    51,   133,   134,    52,    82,
     104,   105,   172,   250,   174,   175,   176,   205,   177,   178,
     179,   206,   207,   208,   180,   209,   210,   211,    58,    59,
      60,    96,    44,    54,    55,    56,    16,    46,    97,    98,
      17,    18,   110,   111,    19,    20,   184,    22,    23,   120,
     148,   149,   185,   186,   143,   225,   198,   226,    24,   201,
      25,    26,   190,   191,    27,    28,   188,   241
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      53,    21,   173,    99,   181,    79,    15,    76,     1,    80,
      45,    -6,   108,    66,    64,     2,     3,     3,    15,   139,
       4,     4,   136,   124,   217,   101,    81,   112,     7,     7,
     217,   220,   129,   204,    57,   181,     6,   102,    61,     3,
      74,   222,   107,     4,    84,     6,     6,   115,    53,   117,
     118,     7,   121,  -148,   123,    83,    77,   125,     6,   127,
     244,   181,    86,    88,   141,     6,    89,    90,    91,    92,
      93,    94,   249,   252,   154,   229,   155,   181,   103,   106,
     150,   100,   151,    79,   256,   216,   116,    81,     6,   157,
     109,   112,   119,   126,   142,   132,   135,   144,    53,   145,
     183,   153,   106,   152,     6,   195,   197,   187,   181,   181,
     138,   214,   218,   230,   227,   233,   109,   147,   236,   181,
     181,  -136,   237,   239,  -136,   247,    53,   248,  -136,  -136,
     254,   259,   140,   182,   257,    62,   128,  -136,   171,   202,
    -136,   131,  -136,    -4,   193,   189,   219,   196,   231,   234,
     200,    85,   137,  -136,    63,  -136,   122,     1,  -136,  -136,
     194,   255,   212,   192,     2,   221,     3,   253,   213,   171,
       4,    67,   245,    68,     0,     0,     5,     6,     7,   242,
      68,    69,   215,   199,    70,     0,     0,   261,    69,     0,
       0,    70,   189,   223,     0,   171,     0,    71,   224,     0,
       0,     0,    72,    73,    71,   232,     0,     0,   235,    72,
      73,   171,     0,     0,     0,     0,   240,   260,     0,     0,
       0,   262,   243,     0,     0,   246,     0,   224,     0,     0,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     0,   171,   171,     0,     0,     0,     0,     0,   235,
       0,     0,   258,   171,   171,   146,     0,     0,    29,     0,
      30,     0,     0,     0,    31,     0,    32,    33,    34,    35,
       0,    36,     0,     0,     0,     3,     0,    48,     0,     4,
       0,     0,    37,     0,    38,    39,     0,     7,    40,    41,
      42,    29,     0,    30,     0,     0,     0,   158,   159,   160,
     161,    34,    35,   162,    36,   163,   164,     0,     3,   165,
     166,     0,     4,   203,     0,   167,     0,    38,    39,   168,
       7,   169,    41,    42,   170,    29,     0,    30,     0,     0,
       0,   158,   159,   160,   161,    34,    35,   162,    36,   163,
     164,     0,     3,   165,   166,     0,     4,   228,     0,   167,
       0,    38,    39,   168,     7,   169,    41,    42,   170,    29,
       0,    30,     0,     0,     0,   158,   159,   160,   161,    34,
      35,   162,    36,   163,   164,     0,     3,   165,   166,     0,
       4,     0,     0,   167,     0,    38,    39,   168,     7,   169,
      41,    42,   170,    29,     0,    30,     0,     0,     0,   158,
     159,   160,   161,    34,    35,   162,    36,   163,   251,     0,
       3,   165,   166,     0,     4,     0,     0,   167,     0,    38,
      39,   168,     7,   169,    41,    42,    29,     0,    30,    47,
       0,     0,    31,     0,    32,    33,    34,    35,     0,    36,
       0,     0,     0,     3,     0,    48,     0,     4,     0,    49,
      37,     0,    38,    39,     0,     7,    40,    41,    42,    29,
       0,    30,    47,     0,     0,    31,     0,    32,    33,    34,
      35,     0,    36,     0,     0,     0,     3,     0,    48,     0,
       4,     0,    78,    37,     0,    38,    39,     0,     7,    40,
      41,    42,    29,     0,    30,    47,     0,     0,    31,     0,
      32,    33,    34,    35,     0,    36,     0,     0,     0,     3,
       0,    48,     0,     4,     0,   156,    37,     0,    38,    39,
       0,     7,    40,    41,    42,    29,    57,    30,     0,     0,
       0,    31,     0,    32,    33,    34,    35,     0,    36,     0,
       0,     0,     3,     0,    75,     0,     4,     0,     0,    37,
       0,    38,    39,     0,     7,    40,    41,    42,    29,     0,
      30,     0,     0,     0,    31,     0,    32,    33,    34,    35,
       0,    36,    95,     0,     0,     3,     0,    48,     0,     4,
       0,     0,    37,     0,    38,    39,     0,     7,    40,    41,
      42,    29,     0,    30,    47,     0,     0,    31,     0,    32,
      33,    34,    35,     0,    36,     0,     0,     0,     3,     0,
      48,     0,     4,     0,     0,    37,     0,    38,    39,     0,
       7,    40,    41,    42,    29,     0,    30,     0,     0,     0,
      31,     0,    32,    33,    34,    35,     0,    36,     0,     0,
       0,     3,     0,    48,     0,     4,     0,     0,    37,   130,
      38,    39,     0,     7,    40,    41,    42,    29,     0,    30,
       0,     0,     0,    31,     0,    32,    33,    34,    35,     0,
      36,     0,     0,     0,     3,     0,    48,     0,     4,     0,
       0,    37,     0,    38,    39,     0,     7,    40,    41,    42,
      29,     0,    30,     0,     0,     0,    31,     0,    32,    33,
      34,    35,     0,    36,     0,     0,     0,     3,     0,     0,
       0,     4,     0,     0,    37,     0,    38,    39,     0,     7,
      40,    41,    42,    29,     0,    30,     0,     0,     0,     0,
       0,   160,   161,    34,    35,     0,    36,     0,     0,     0,
       3,     0,   166,     0,     4,     0,     0,   167,     0,    38,
      39,     0,     7,     0,    41,    42
};

static const yytype_int16 yycheck[] =
{
       2,     0,   132,    75,   132,    50,     0,    47,    14,     5,
       1,     0,    83,    15,    13,    21,    23,    23,    12,    31,
      27,    27,    29,    95,   186,    76,    22,    39,    35,    35,
     192,    29,   103,   163,     7,   163,    34,    77,     0,    23,
      25,    29,    82,    27,    21,    34,    34,    87,    50,    89,
      90,    35,    92,    29,    94,    57,    47,    97,    34,    99,
      29,   189,    22,     7,   115,    34,    68,    69,    70,    71,
      72,    73,   236,   237,   125,   205,   127,   205,    80,    81,
     120,    21,   122,   128,   248,    31,    88,    22,    34,   129,
      84,    39,    17,     4,    22,     5,     5,    21,   100,    21,
       5,    28,   104,    10,    34,     3,    21,    30,   236,   237,
     112,   183,    25,    29,    26,    29,   110,   119,     5,   247,
     248,     0,    10,     5,     3,     5,   128,     5,     7,     8,
      26,     5,   113,   135,   253,    12,   100,    16,   132,   157,
      19,   104,    21,     0,   146,   144,   189,   149,   207,   210,
     152,    59,   110,    32,    13,    34,    93,    14,    37,    38,
     146,   243,   164,   145,    21,   191,    23,   239,   170,   163,
      27,     6,   226,     8,    -1,    -1,    33,    34,    35,   219,
       8,    16,   184,   151,    19,    -1,    -1,   259,    16,    -1,
      -1,    19,   191,   195,    -1,   189,    -1,    32,   197,    -1,
      -1,    -1,    37,    38,    32,   207,    -1,    -1,   210,    37,
      38,   205,    -1,    -1,    -1,    -1,   218,   257,    -1,    -1,
      -1,   261,   224,    -1,    -1,   227,    -1,   226,    -1,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,    -1,
      -1,    -1,   236,   237,    -1,    -1,    -1,    -1,    -1,   251,
      -1,    -1,   254,   247,   248,     3,    -1,    -1,     6,    -1,
       8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,
      -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,    37,
      38,     6,    -1,     8,    -1,    -1,    -1,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    -1,    23,    24,
      25,    -1,    27,    28,    -1,    30,    -1,    32,    33,    34,
      35,    36,    37,    38,    39,     6,    -1,     8,    -1,    -1,
      -1,    12,    13,    14,    15,    16,    17,    18,    19,    20,
      21,    -1,    23,    24,    25,    -1,    27,    28,    -1,    30,
      -1,    32,    33,    34,    35,    36,    37,    38,    39,     6,
      -1,     8,    -1,    -1,    -1,    12,    13,    14,    15,    16,
      17,    18,    19,    20,    21,    -1,    23,    24,    25,    -1,
      27,    -1,    -1,    30,    -1,    32,    33,    34,    35,    36,
      37,    38,    39,     6,    -1,     8,    -1,    -1,    -1,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    -1,
      23,    24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,
      33,    34,    35,    36,    37,    38,     6,    -1,     8,     9,
      -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,    19,
      -1,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,    29,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,     9,    -1,    -1,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,
      27,    -1,    29,    30,    -1,    32,    33,    -1,    35,    36,
      37,    38,     6,    -1,     8,     9,    -1,    -1,    12,    -1,
      14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,
      -1,    25,    -1,    27,    -1,    29,    30,    -1,    32,    33,
      -1,    35,    36,    37,    38,     6,     7,     8,    -1,    -1,
      -1,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    -1,    25,    -1,    27,    -1,    -1,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38,     6,    -1,
       8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,
      -1,    19,    20,    -1,    -1,    23,    -1,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,    37,
      38,     6,    -1,     8,     9,    -1,    -1,    12,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,
      25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,
      35,    36,    37,    38,     6,    -1,     8,    -1,    -1,    -1,
      12,    -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,
      -1,    23,    -1,    25,    -1,    27,    -1,    -1,    30,    31,
      32,    33,    -1,    35,    36,    37,    38,     6,    -1,     8,
      -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,
      19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,
      -1,    30,    -1,    32,    33,    -1,    35,    36,    37,    38,
       6,    -1,     8,    -1,    -1,    -1,    12,    -1,    14,    15,
      16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,    -1,
      -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,    35,
      36,    37,    38,     6,    -1,     8,    -1,    -1,    -1,    -1,
      -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,
      23,    -1,    25,    -1,    27,    -1,    -1,    30,    -1,    32,
      33,    -1,    35,    -1,    37,    38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    14,    21,    23,    27,    33,    34,    35,    41,    42,
      43,    44,    45,    46,    47,    48,    86,    90,    91,    94,
      95,    96,    97,    98,   108,   110,   111,   114,   115,     6,
       8,    12,    14,    15,    16,    17,    19,    30,    32,    33,
      36,    37,    38,    48,    82,    83,    87,     9,    25,    29,
      54,    55,    58,    81,    83,    84,    85,     7,    78,    79,
      80,     0,    44,    94,    96,    49,    81,     6,     8,    16,
      19,    32,    37,    38,    25,    25,    78,    83,    29,    55,
       5,    22,    59,    81,    21,    80,    22,    50,     7,    81,
      81,    81,    81,    81,    81,    20,    81,    88,    89,    88,
      21,    56,    78,    81,    60,    61,    81,    78,    59,    48,
      92,    93,    39,    51,    52,    78,    81,    78,    78,    17,
      99,    78,    99,    78,    88,    78,     4,    78,    54,    59,
      31,    61,     5,    56,    57,     5,    29,    93,    81,    31,
      52,    56,    22,   104,    21,    21,     3,    81,   100,   101,
      78,    78,    10,    28,    56,    56,    29,    78,    12,    13,
      14,    15,    18,    20,    21,    24,    25,    30,    34,    36,
      39,    48,    62,    63,    64,    65,    66,    68,    69,    70,
      74,    82,    81,     5,    96,   102,   103,    30,   116,    96,
     112,   113,   103,    81,   100,     3,    81,    21,   106,   106,
      81,   109,    57,    28,    63,    67,    71,    72,    73,    75,
      76,    77,    81,    81,    88,    81,    31,   102,    25,    68,
      29,   112,    29,    81,    96,   105,   107,    26,    28,    63,
      29,    73,    81,    29,    77,    81,     5,    10,    53,     5,
      81,   117,    78,    81,    29,   105,    81,     5,     5,    62,
      63,    21,    62,    88,    26,   104,    62,    53,    81,     5,
      78,    88,    78
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    43,    44,    44,    45,
      45,    46,    46,    47,    47,    47,    48,    48,    48,    49,
      49,    50,    50,    51,    51,    52,    53,    53,    54,    54,
      55,    55,    55,    56,    57,    57,    58,    58,    59,    59,
      60,    60,    61,    62,    62,    62,    62,    62,    62,    62,
      62,    62,    63,    63,    63,    64,    65,    66,    66,    67,
      67,    68,    68,    68,    68,    68,    68,    69,    70,    70,
      71,    71,    72,    72,    73,    74,    75,    75,    76,    76,
      77,    78,    78,    79,    79,    80,    81,    81,    82,    82,
      82,    82,    82,    82,    82,    82,    82,    83,    83,    83,
      83,    83,    83,    83,    84,    85,    85,    86,    87,    87,
      88,    88,    89,    89,    90,    90,    90,    91,    92,    92,
      93,    94,    94,    94,    94,    94,    94,    95,    96,    96,
      97,    98,    99,    99,    99,    99,   100,   100,   101,   101,
     102,   103,   103,   104,   104,   105,   106,   106,   107,   107,
     107,   108,   109,   109,   110,   111,   112,   113,   113,   114,
     115,   116,   116,   117,   117
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     0,     1,     1,     1,     1,     1,
       2,     1,     2,     5,     3,     2,     1,     1,     1,     0,
       1,     0,     3,     1,     2,     5,     0,     2,     1,     2,
       1,     1,     1,     3,     0,     1,     6,     4,     0,     3,
       1,     2,     3,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     2,     2,     3,     1,
       2,     1,     1,     1,     1,     1,     1,     1,     0,     3,
       0,     1,     1,     2,     3,     3,     0,     1,     1,     2,
       3,     0,     1,     1,     2,     3,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     3,     5,     3,     6,     0,     1,
       1,     2,     1,     3,     1,     1,     1,     5,     1,     2,
       3,     1,     1,     1,     1,     1,     1,     1,     0,     1,
       4,     6,     0,     3,     2,     2,     1,     3,     1,     2,
       6,     1,     2,     0,     3,     6,     0,     3,     0,     1,
       2,     6,     1,     3,     6,     7,     3,     1,     2,     7,
       8,     0,     1,     1,     3
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
#line 1866 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
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
#line 1887 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 4: /* definitions_list: %empty  */
#line 112 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = GraphQL_Language_Nodes_NONE; }
#line 1893 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 5: /* definitions_list: executable_definitions  */
#line 113 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = yyvsp[0]; }
#line 1899 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 6: /* definitions_list: type_system_definitions  */
#line 114 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = yyvsp[0]; }
#line 1905 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 9: /* executable_definitions: executable_definition  */
#line 121 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1911 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 10: /* executable_definitions: executable_definitions executable_definition  */
#line 122 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { rb_ary_push(yyval, yyvsp[0]); }
#line 1917 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 11: /* type_system_definitions: type_system_definition  */
#line 125 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1923 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 12: /* type_system_definitions: type_system_definitions type_definition  */
#line 126 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { rb_ary_push(yyval, yyvsp[0]); }
#line 1929 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 13: /* operation_definition: operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set  */
#line 130 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 1945 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 14: /* operation_definition: LCURLY selection_list RCURLY  */
#line 141 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 1961 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 15: /* operation_definition: LCURLY RCURLY  */
#line 152 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 1977 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 19: /* operation_name_opt: %empty  */
#line 170 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 1983 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 21: /* variable_definitions_opt: %empty  */
#line 174 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = GraphQL_Language_Nodes_NONE; }
#line 1989 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 22: /* variable_definitions_opt: LPAREN variable_definitions_list RPAREN  */
#line 175 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = yyvsp[-1]; }
#line 1995 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 23: /* variable_definitions_list: variable_definition  */
#line 178 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2001 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 24: /* variable_definitions_list: variable_definitions_list variable_definition  */
#line 179 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 2007 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 25: /* variable_definition: VAR_SIGN name COLON type default_value_opt  */
#line 182 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_VariableDefinition, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2021 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 26: /* default_value_opt: %empty  */
#line 193 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = Qnil; }
#line 2027 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 27: /* default_value_opt: EQUALS literal_value  */
#line 194 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = yyvsp[0]; }
#line 2033 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 28: /* selection_list: selection  */
#line 197 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2039 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 29: /* selection_list: selection_list selection  */
#line 198 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2045 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 33: /* selection_set: LCURLY selection_list RCURLY  */
#line 206 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   { yyval = yyvsp[-1]; }
#line 2051 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 34: /* selection_set_opt: %empty  */
#line 209 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = rb_ary_new(); }
#line 2057 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 36: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 213 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2073 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 37: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 224 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2089 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 38: /* arguments_opt: %empty  */
#line 237 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = GraphQL_Language_Nodes_NONE; }
#line 2095 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 39: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 238 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = yyvsp[-1]; }
#line 2101 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 40: /* arguments_list: argument  */
#line 241 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2107 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 41: /* arguments_list: arguments_list argument  */
#line 242 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { rb_ary_push(yyval, yyvsp[0]); }
#line 2113 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 42: /* argument: name COLON input_value  */
#line 245 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2126 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 43: /* literal_value: FLOAT  */
#line 255 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_f"), 0); }
#line 2132 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 44: /* literal_value: INT  */
#line 256 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_i"), 0); }
#line 2138 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 45: /* literal_value: STRING  */
#line 257 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2144 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 46: /* literal_value: TRUE_LITERAL  */
#line 258 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qtrue; }
#line 2150 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 47: /* literal_value: FALSE_LITERAL  */
#line 259 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qfalse; }
#line 2156 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 55: /* null_value: NULL_LITERAL  */
#line 270 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                           {
    yyval = rb_funcall(GraphQL_Language_Nodes_NullValue, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2168 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 56: /* variable: VAR_SIGN name  */
#line 278 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          {
    yyval = rb_funcall(GraphQL_Language_Nodes_VariableIdentifier, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[-1], 1),
      rb_ary_entry(yyvsp[-1], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2180 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 57: /* list_value: LBRACKET RBRACKET  */
#line 287 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2186 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 58: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 288 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[-1]; }
#line 2192 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 59: /* list_value_list: input_value  */
#line 291 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2198 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 60: /* list_value_list: list_value_list input_value  */
#line 292 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 2204 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 67: /* enum_value: enum_name  */
#line 302 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        {
    yyval = rb_funcall(GraphQL_Language_Nodes_Enum, rb_intern("from_a"), 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2216 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 69: /* object_value: LCURLY object_value_list_opt RCURLY  */
#line 311 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          {
      yyval = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
        rb_ary_entry(yyvsp[-2], 1),
        rb_ary_entry(yyvsp[-2], 2),
        yyvsp[-1]
      );
    }
#line 2228 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 70: /* object_value_list_opt: %empty  */
#line 320 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2234 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 72: /* object_value_list: object_value_field  */
#line 324 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2240 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 73: /* object_value_list: object_value_list object_value_field  */
#line 325 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2246 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 74: /* object_value_field: name COLON input_value  */
#line 328 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2259 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 75: /* object_literal_value: LCURLY object_literal_value_list_opt RCURLY  */
#line 339 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
        yyval = rb_funcall(GraphQL_Language_Nodes_InputObject, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          yyvsp[-1]
        );
      }
#line 2271 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 76: /* object_literal_value_list_opt: %empty  */
#line 348 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2277 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 78: /* object_literal_value_list: object_literal_value_field  */
#line 352 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2283 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 79: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 353 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2289 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 80: /* object_literal_value_field: name COLON literal_value  */
#line 356 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
        yyval = rb_funcall(GraphQL_Language_Nodes_Argument, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2302 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 81: /* directives_list_opt: %empty  */
#line 367 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = GraphQL_Language_Nodes_NONE; }
#line 2308 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 83: /* directives_list: directive  */
#line 371 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2314 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 84: /* directives_list: directives_list directive  */
#line 372 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2320 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 85: /* directive: DIR_SIGN name arguments_opt  */
#line 374 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                         {
    yyval = rb_funcall(GraphQL_Language_Nodes_Directive, rb_intern("from_a"), 4,
      rb_ary_entry(yyvsp[-2], 1),
      rb_ary_entry(yyvsp[-2], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2333 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 104: /* fragment_spread: ELLIPSIS name_without_on directives_list_opt  */
#line 409 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   {
        yyval = rb_funcall(GraphQL_Language_Nodes_FragmentSpread, rb_intern("from_a"), 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0]
        );
      }
#line 2346 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 105: /* inline_fragment: ELLIPSIS ON type directives_list_opt selection_set  */
#line 419 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         {
        yyval = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2360 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 106: /* inline_fragment: ELLIPSIS directives_list_opt selection_set  */
#line 428 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = rb_funcall(GraphQL_Language_Nodes_InlineFragment, rb_intern("from_a"), 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2374 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 107: /* fragment_definition: FRAGMENT fragment_name_opt ON type directives_list_opt selection_set  */
#line 439 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2389 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 108: /* fragment_name_opt: %empty  */
#line 451 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2395 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 109: /* fragment_name_opt: name_without_on  */
#line 452 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2401 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 111: /* type: nullable_type BANG  */
#line 456 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_funcall(GraphQL_Language_Nodes_NonNullType, rb_intern("from_a"), 3, rb_funcall(yyvsp[-1], rb_intern("line"), 0), rb_funcall(yyvsp[-1], rb_intern("col"), 0), yyvsp[-1]); }
#line 2407 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 112: /* nullable_type: name  */
#line 459 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2419 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 113: /* nullable_type: LBRACKET type RBRACKET  */
#line 466 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = rb_funcall(GraphQL_Language_Nodes_ListType, rb_intern("from_a"), 3,
          rb_funcall(yyvsp[-1], rb_intern("line"), 0),
          rb_funcall(yyvsp[-1], rb_intern("col"), 0),
          yyvsp[-1]
        );
      }
#line 2431 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 117: /* schema_definition: SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 480 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2447 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 119: /* operation_type_definition_list: operation_type_definition_list operation_type_definition  */
#line 494 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      rb_funcall(yyval, rb_intern("merge!"), 1, yyvsp[-1]);
    }
#line 2455 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 120: /* operation_type_definition: operation_type COLON name  */
#line 499 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_hash_new();
        rb_hash_aset(yyval, rb_ary_entry(yyvsp[-2], 3), rb_ary_entry(yyvsp[0], 3));
      }
#line 2464 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 128: /* description_opt: %empty  */
#line 515 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = Qnil; }
#line 2470 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 130: /* scalar_type_definition: description_opt SCALAR name directives_list_opt  */
#line 519 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2485 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 131: /* object_type_definition: description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 531 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2502 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 132: /* implements_opt: %empty  */
#line 545 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2508 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 133: /* implements_opt: IMPLEMENTS AMP interfaces_list  */
#line 546 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                     { yyval = yyvsp[0]; }
#line 2514 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 134: /* implements_opt: IMPLEMENTS interfaces_list  */
#line 547 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                 { yyval = yyvsp[0]; }
#line 2520 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 135: /* implements_opt: IMPLEMENTS legacy_interfaces_list  */
#line 548 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[0]; }
#line 2526 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 136: /* interfaces_list: name  */
#line 551 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2539 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 137: /* interfaces_list: interfaces_list AMP name  */
#line 559 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
      VALUE new_name =  rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3));
      rb_ary_push(yyval, new_name);
    }
#line 2548 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 138: /* legacy_interfaces_list: name  */
#line 565 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2561 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 139: /* legacy_interfaces_list: legacy_interfaces_list name  */
#line 573 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  {
      rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
    }
#line 2569 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 140: /* input_value_definition: description_opt name COLON type default_value_opt directives_list_opt  */
#line 578 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2586 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 141: /* input_value_definition_list: input_value_definition  */
#line 592 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2592 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 142: /* input_value_definition_list: input_value_definition_list input_value_definition  */
#line 593 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { rb_ary_push(yyval, yyvsp[0]); }
#line 2598 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 143: /* arguments_definitions_opt: %empty  */
#line 596 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2604 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 144: /* arguments_definitions_opt: LPAREN input_value_definition_list RPAREN  */
#line 597 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = yyvsp[-1]; }
#line 2610 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 145: /* field_definition: description_opt name arguments_definitions_opt COLON type directives_list_opt  */
#line 600 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2627 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 146: /* field_definition_list_opt: %empty  */
#line 614 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2633 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 147: /* field_definition_list_opt: LCURLY field_definition_list RCURLY  */
#line 615 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          { yyval = yyvsp[-1]; }
#line 2639 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 148: /* field_definition_list: %empty  */
#line 618 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2645 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 149: /* field_definition_list: field_definition  */
#line 619 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2651 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 150: /* field_definition_list: field_definition_list field_definition  */
#line 620 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { rb_ary_push(yyval, yyvsp[0]); }
#line 2657 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 151: /* interface_type_definition: description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 623 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2674 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 152: /* union_members: name  */
#line 637 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_member = rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_member);
      }
#line 2687 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 153: /* union_members: union_members PIPE name  */
#line 645 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              {
        rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_TypeName, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
      }
#line 2695 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 154: /* union_type_definition: description_opt UNION name directives_list_opt EQUALS union_members  */
#line 650 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2711 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 155: /* enum_type_definition: description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 663 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2727 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 156: /* enum_value_definition: description_opt enum_name directives_list_opt  */
#line 676 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2742 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 157: /* enum_value_definitions: enum_value_definition  */
#line 688 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2748 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 158: /* enum_value_definitions: enum_value_definitions enum_value_definition  */
#line 689 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { rb_ary_push(yyval, yyvsp[0]); }
#line 2754 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 159: /* input_object_type_definition: description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 692 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2770 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 160: /* directive_definition: description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations  */
#line 705 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
#line 2787 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 163: /* directive_locations: name  */
#line 723 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2793 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 164: /* directive_locations: directive_locations PIPE name  */
#line 724 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { rb_ary_push(yyval, rb_funcall(GraphQL_Language_Nodes_DirectiveLocation, rb_intern("from_a"), 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2799 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;


#line 2803 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

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

#line 726 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"


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
      rb_ivar_get(parser, rb_intern("@query_string"))
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
