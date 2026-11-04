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
#define YYSTACK_USE_ALLOCA 1

int yylex(YYSTYPE *, VALUE, VALUE);
NORETURN(void yyerror(VALUE, VALUE, const char*));

static VALUE GraphQL_Language_Nodes_NONE;
static VALUE r_string_query;

#define MAKE_AST_NODE(node_class_name, nargs, ...) rb_funcall(GraphQL_Language_Nodes_##node_class_name, rb_intern("from_a"), nargs + 1, filename,__VA_ARGS__)

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

#line 126 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

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




int yyparse (VALUE parser, VALUE filename);



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
  YYSYMBOL_scalar_value = 61,              /* scalar_value  */
  YYSYMBOL_literal_value = 62,             /* literal_value  */
  YYSYMBOL_input_value = 63,               /* input_value  */
  YYSYMBOL_null_value = 64,                /* null_value  */
  YYSYMBOL_variable = 65,                  /* variable  */
  YYSYMBOL_list_value = 66,                /* list_value  */
  YYSYMBOL_list_value_list = 67,           /* list_value_list  */
  YYSYMBOL_list_literal_value = 68,        /* list_literal_value  */
  YYSYMBOL_list_literal_value_list = 69,   /* list_literal_value_list  */
  YYSYMBOL_enum_name = 70,                 /* enum_name  */
  YYSYMBOL_enum_value = 71,                /* enum_value  */
  YYSYMBOL_object_value = 72,              /* object_value  */
  YYSYMBOL_object_value_list_opt = 73,     /* object_value_list_opt  */
  YYSYMBOL_object_value_list = 74,         /* object_value_list  */
  YYSYMBOL_object_value_field = 75,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 76,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list_opt = 77, /* object_literal_value_list_opt  */
  YYSYMBOL_object_literal_value_list = 78, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 79, /* object_literal_value_field  */
  YYSYMBOL_directives_list_opt = 80,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 81,           /* directives_list  */
  YYSYMBOL_directive = 82,                 /* directive  */
  YYSYMBOL_name = 83,                      /* name  */
  YYSYMBOL_schema_keyword = 84,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 85,           /* name_without_on  */
  YYSYMBOL_fragment_spread = 86,           /* fragment_spread  */
  YYSYMBOL_inline_fragment = 87,           /* inline_fragment  */
  YYSYMBOL_fragment_definition = 88,       /* fragment_definition  */
  YYSYMBOL_fragment_name_opt = 89,         /* fragment_name_opt  */
  YYSYMBOL_type = 90,                      /* type  */
  YYSYMBOL_nullable_type = 91,             /* nullable_type  */
  YYSYMBOL_type_system_definition = 92,    /* type_system_definition  */
  YYSYMBOL_schema_definition = 93,         /* schema_definition  */
  YYSYMBOL_operation_type_definition_list_opt = 94, /* operation_type_definition_list_opt  */
  YYSYMBOL_operation_type_definition_list = 95, /* operation_type_definition_list  */
  YYSYMBOL_operation_type_definition = 96, /* operation_type_definition  */
  YYSYMBOL_type_definition = 97,           /* type_definition  */
  YYSYMBOL_description = 98,               /* description  */
  YYSYMBOL_description_opt = 99,           /* description_opt  */
  YYSYMBOL_scalar_type_definition = 100,   /* scalar_type_definition  */
  YYSYMBOL_object_type_definition = 101,   /* object_type_definition  */
  YYSYMBOL_implements_opt = 102,           /* implements_opt  */
  YYSYMBOL_interfaces_list = 103,          /* interfaces_list  */
  YYSYMBOL_legacy_interfaces_list = 104,   /* legacy_interfaces_list  */
  YYSYMBOL_input_value_definition = 105,   /* input_value_definition  */
  YYSYMBOL_input_value_definition_list = 106, /* input_value_definition_list  */
  YYSYMBOL_arguments_definitions_opt = 107, /* arguments_definitions_opt  */
  YYSYMBOL_field_definition = 108,         /* field_definition  */
  YYSYMBOL_field_definition_list_opt = 109, /* field_definition_list_opt  */
  YYSYMBOL_field_definition_list = 110,    /* field_definition_list  */
  YYSYMBOL_interface_type_definition = 111, /* interface_type_definition  */
  YYSYMBOL_pipe_opt = 112,                 /* pipe_opt  */
  YYSYMBOL_union_members = 113,            /* union_members  */
  YYSYMBOL_union_type_definition = 114,    /* union_type_definition  */
  YYSYMBOL_enum_type_definition = 115,     /* enum_type_definition  */
  YYSYMBOL_enum_value_definition = 116,    /* enum_value_definition  */
  YYSYMBOL_enum_value_definitions = 117,   /* enum_value_definitions  */
  YYSYMBOL_input_object_type_definition = 118, /* input_object_type_definition  */
  YYSYMBOL_directive_definition = 119,     /* directive_definition  */
  YYSYMBOL_directive_repeatable_opt = 120, /* directive_repeatable_opt  */
  YYSYMBOL_directive_locations = 121,      /* directive_locations  */
  YYSYMBOL_type_system_extension = 122,    /* type_system_extension  */
  YYSYMBOL_schema_extension = 123,         /* schema_extension  */
  YYSYMBOL_type_extension = 124,           /* type_extension  */
  YYSYMBOL_scalar_type_extension = 125,    /* scalar_type_extension  */
  YYSYMBOL_object_type_extension = 126,    /* object_type_extension  */
  YYSYMBOL_interface_type_extension = 127, /* interface_type_extension  */
  YYSYMBOL_union_type_extension = 128,     /* union_type_extension  */
  YYSYMBOL_enum_type_extension = 129,      /* enum_type_extension  */
  YYSYMBOL_input_object_type_extension = 130, /* input_object_type_extension  */
  YYSYMBOL_NamedTypeForCondition = 131     /* NamedTypeForCondition  */
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
#define YYFINAL  79
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   830

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  92
/* YYNRULES -- Number of rules.  */
#define YYNRULES  191
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  319

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
       0,   107,   107,   109,   123,   124,   127,   128,   129,   132,
     133,   136,   147,   158,   171,   172,   173,   176,   177,   180,
     181,   184,   185,   188,   200,   201,   204,   205,   208,   209,
     210,   213,   216,   217,   220,   231,   244,   245,   248,   249,
     252,   262,   263,   264,   265,   266,   267,   268,   271,   272,
     273,   276,   277,   278,   279,   281,   289,   298,   299,   302,
     303,   306,   307,   310,   311,   314,   315,   316,   317,   319,
     328,   337,   338,   341,   342,   345,   356,   365,   366,   369,
     370,   373,   384,   385,   388,   389,   391,   401,   402,   405,
     406,   407,   408,   409,   410,   411,   412,   413,   414,   415,
     416,   419,   420,   421,   422,   423,   424,   428,   438,   447,
     458,   470,   471,   474,   475,   478,   485,   494,   495,   496,
     499,   512,   513,   516,   520,   525,   530,   531,   532,   533,
     534,   535,   537,   540,   541,   544,   556,   570,   571,   572,
     573,   576,   584,   590,   598,   603,   617,   618,   621,   622,
     625,   639,   640,   643,   644,   645,   648,   662,   663,   666,
     674,   679,   692,   705,   717,   718,   721,   734,   748,   749,
     752,   753,   757,   758,   761,   772,   784,   785,   786,   787,
     788,   789,   791,   801,   813,   825,   834,   845,   854,   865,
     874,   885
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
  "arguments_opt", "arguments_list", "argument", "scalar_value",
  "literal_value", "input_value", "null_value", "variable", "list_value",
  "list_value_list", "list_literal_value", "list_literal_value_list",
  "enum_name", "enum_value", "object_value", "object_value_list_opt",
  "object_value_list", "object_value_field", "object_literal_value",
  "object_literal_value_list_opt", "object_literal_value_list",
  "object_literal_value_field", "directives_list_opt", "directives_list",
  "directive", "name", "schema_keyword", "name_without_on",
  "fragment_spread", "inline_fragment", "fragment_definition",
  "fragment_name_opt", "type", "nullable_type", "type_system_definition",
  "schema_definition", "operation_type_definition_list_opt",
  "operation_type_definition_list", "operation_type_definition",
  "type_definition", "description", "description_opt",
  "scalar_type_definition", "object_type_definition", "implements_opt",
  "interfaces_list", "legacy_interfaces_list", "input_value_definition",
  "input_value_definition_list", "arguments_definitions_opt",
  "field_definition", "field_definition_list_opt", "field_definition_list",
  "interface_type_definition", "pipe_opt", "union_members",
  "union_type_definition", "enum_type_definition", "enum_value_definition",
  "enum_value_definitions", "input_object_type_definition",
  "directive_definition", "directive_repeatable_opt",
  "directive_locations", "type_system_extension", "schema_extension",
  "type_extension", "scalar_type_extension", "object_type_extension",
  "interface_type_extension", "union_type_extension",
  "enum_type_extension", "input_object_type_extension",
  "NamedTypeForCondition", YY_NULLPTR
  };
  return yy_sname[yysymbol];
}
#endif

#define YYPACT_NINF (-232)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-154)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     195,   167,   792,   528,  -232,  -232,    12,  -232,  -232,    17,
    -232,    82,  -232,  -232,  -232,   759,  -232,  -232,  -232,  -232,
    -232,   120,  -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,
    -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,   759,   759,
     759,   759,    12,   759,   759,  -232,  -232,  -232,  -232,  -232,
    -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,
    -232,  -232,  -232,  -232,    -7,   627,  -232,  -232,   561,  -232,
    -232,    11,  -232,  -232,  -232,   759,    19,    12,  -232,  -232,
    -232,    16,  -232,    37,   759,   759,   759,   759,   759,   759,
      12,    12,    29,    12,    27,    28,    29,    12,   759,   759,
      76,    12,  -232,  -232,   759,   759,    12,    99,    60,  -232,
    -232,    59,    12,   759,    12,    12,    29,    12,    29,    12,
      83,    28,   122,    28,   294,    12,    12,    60,    12,   100,
      74,  -232,    12,    12,   660,  -232,  -232,    99,   693,  -232,
     142,    76,  -232,   155,   139,  -232,   759,   -16,  -232,    76,
     147,   140,   149,    12,  -232,    12,   161,   138,   138,   759,
     202,   174,   759,   158,   250,   158,   156,    76,    76,   594,
      12,  -232,  -232,   395,  -232,  -232,   759,  -232,  -232,   176,
    -232,  -232,  -232,   138,   154,   138,   138,   158,   158,   156,
     237,  -232,    34,   759,  -232,    65,  -232,   174,   759,  -232,
      78,  -232,  -232,  -232,  -232,   759,   162,  -232,  -232,  -232,
      76,  -232,  -232,  -232,  -232,   327,   759,  -232,  -232,  -232,
    -232,   759,  -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,
    -232,  -232,  -232,   726,    88,  -232,   164,    89,   116,  -232,
    -232,   162,    12,  -232,  -232,   182,  -232,  -232,  -232,   759,
    -232,   125,  -232,   759,  -232,  -232,  -232,   361,   165,   759,
    -232,   186,  -232,   726,  -232,   187,   192,  -232,   759,  -232,
    -232,  -232,   726,   147,  -232,  -232,  -232,  -232,  -232,  -232,
    -232,   395,   170,   495,    12,  -232,  -232,   175,   187,   206,
    -232,  -232,   429,   759,  -232,  -232,  -232,  -232,  -232,   759,
      12,   726,  -232,  -232,   462,   178,   759,  -232,   207,  -232,
    -232,    12,  -232,  -232,  -232,  -232,   495,  -232,  -232
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
     133,     0,   111,     0,    15,    14,    82,   132,    16,     0,
       2,   133,     4,     6,     9,    17,    10,     7,   117,   118,
     134,     0,   126,   127,   128,   129,   130,   131,   119,     8,
     172,   173,   176,   177,   178,   179,   180,   181,     0,     0,
       0,     0,    82,     0,     0,    97,    95,    98,   103,    99,
     101,    96,    92,    93,   104,   100,    90,    89,   102,    91,
      94,   105,   106,   112,     0,    82,    88,    13,     0,    26,
      28,    36,    87,    29,    30,     0,   121,    83,    84,     1,
       5,    19,    18,     0,     0,     0,     0,     0,     0,     0,
      82,    82,   137,     0,     0,   175,   137,    82,     0,     0,
       0,    82,    12,    27,     0,     0,    82,    36,     0,   120,
      85,     0,    82,     0,    82,    82,   137,    82,   137,    82,
       0,   188,     0,   190,     0,    82,   182,     0,    82,     0,
     186,   191,    82,    82,     0,   109,   107,    36,     0,    38,
       0,    32,    86,     0,     0,   123,     0,     0,    21,     0,
     148,     0,     0,    82,   135,    82,     0,   133,   133,     0,
     141,   139,   140,   151,     0,   151,   157,     0,     0,     0,
      82,    37,    39,     0,    33,    35,     0,   122,   124,     0,
      20,    22,    11,   133,   168,   133,   133,   151,   151,   157,
       0,   164,   133,     0,   146,   133,   141,   138,     0,   144,
     133,   184,   174,   183,   158,     0,   185,   110,   108,    31,
      32,    45,    41,    65,    42,     0,    71,    55,    66,    43,
      44,     0,    67,    51,    40,    46,    52,    53,    69,    47,
      54,    68,   125,     0,   133,   169,     0,   133,   133,   156,
     136,   161,    82,   187,   165,     0,   189,   147,   142,     0,
     154,   133,   159,     0,    34,    57,    59,     0,     0,    72,
      73,     0,    56,     0,   115,    24,   113,   149,     0,   162,
     166,   163,     0,   148,   152,   155,   160,    58,    60,    70,
      74,     0,     0,     0,    82,   114,   170,   167,    24,     0,
      75,   116,     0,    77,    48,    25,    49,    50,    23,     0,
      82,     0,    61,    63,     0,     0,    78,    79,     0,   171,
     145,    82,    62,    64,    76,    80,     0,   150,    81
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -232,  -232,  -232,  -232,   210,  -232,  -232,     0,  -232,  -232,
    -232,    66,   -65,    90,   -67,   -88,    15,  -232,  -100,  -232,
      93,  -226,  -215,  -212,  -232,  -232,  -232,  -232,  -232,  -232,
      43,  -232,  -232,  -232,  -232,   -25,  -232,  -232,  -232,   -69,
      23,   -37,   -71,   -13,  -151,     2,  -232,  -232,  -232,  -232,
    -231,  -232,  -232,  -232,  -232,   108,  -135,  -232,  -232,    10,
    -232,  -232,   -82,    80,  -232,  -187,   -52,   -32,    -9,  -145,
    -232,  -232,  -232,    55,  -232,  -232,  -179,    64,  -232,  -232,
    -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,  -232,
    -232,   159
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,     9,    10,    11,    12,    13,    14,    61,    81,   112,
     147,   148,   284,    68,    69,   174,   175,    70,   106,   138,
     139,   223,   295,   224,   225,   226,   227,   257,   296,   304,
     228,   229,   230,   258,   259,   260,   297,   305,   306,   307,
      76,    77,    78,    71,    62,    72,    73,    74,    16,    64,
     265,   266,    17,    18,   109,   144,   145,    19,    20,   193,
      22,    23,   125,   161,   162,   194,   195,   184,   250,   201,
     251,    24,   205,   206,    25,    26,   191,   192,    27,    28,
     236,   287,    29,    30,    31,    32,    33,    34,    35,    36,
      37,   132
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      15,   103,    82,   256,    63,    95,   110,   142,   247,   178,
      21,    15,   135,   244,   128,   180,   104,    79,    98,    75,
     203,    21,   231,   146,   110,    90,    91,    92,    93,   178,
      96,    97,   282,   105,   153,    75,   155,   170,   111,   231,
     108,   288,   239,   240,   113,   278,   124,   247,   127,   -83,
     110,   247,   110,   121,   123,   110,   126,   294,   244,   110,
     130,   182,   107,   243,   231,    94,   294,   101,     7,   290,
     311,   114,   115,   116,   117,   118,   119,   303,   294,   207,
     208,    75,    -3,     4,   -83,   131,   131,     5,   100,   313,
     294,   137,   140,     1,   246,     8,     2,   134,   146,     7,
     150,   318,   103,     3,   157,     4,   231,  -153,   143,     5,
     166,   160,     7,   120,   122,     6,     7,     8,   269,   267,
     129,   105,     7,     7,   136,   140,    83,   143,    84,   141,
     231,   234,   231,   179,   238,   149,    85,   151,   152,    86,
     154,   231,   156,   158,   143,   270,   196,   173,   163,   199,
       7,   165,    87,   231,   274,   167,   168,    88,    89,     7,
     176,   185,     4,   232,   143,   231,     5,   190,   177,   183,
     186,   189,     7,   222,     8,    38,   187,   198,   188,   200,
     245,   233,   204,    39,   235,   248,    40,   272,   253,   268,
     222,   281,   252,   210,   279,   190,   285,   283,   291,    41,
      42,   299,   190,   261,    43,    44,     1,   314,   262,     2,
     249,   301,   316,   181,  -143,   222,     3,  -143,     4,  -143,
     264,    80,     5,   300,   169,   254,  -143,  -143,     6,     7,
       8,   172,  -143,   242,   280,   164,   273,   315,  -143,   197,
     276,   289,   275,    45,   241,    46,   261,   190,    47,   237,
     264,    49,   213,    51,    52,   286,    53,   222,   133,   264,
       4,   249,   218,     0,     5,   271,     0,    55,     0,    56,
      57,     0,     8,     4,    59,    60,     0,     5,     0,   202,
     308,   222,     0,   222,     0,     8,   309,     0,   264,     0,
       0,     0,   222,   308,     0,     0,     0,   159,     0,     0,
      45,     0,    46,     0,   222,    47,    48,   298,    49,    50,
      51,    52,     0,    53,     0,     0,   222,     4,    54,    66,
       0,     5,     0,   310,    55,     0,    56,    57,     0,     8,
      58,    59,    60,    45,   317,    46,     0,     0,    47,   211,
     212,    49,   213,    51,    52,   214,    53,   215,   216,     0,
       4,   217,   218,     0,     5,   255,     0,    55,     0,    56,
      57,   219,     8,   220,    59,    60,   221,    45,     0,    46,
       0,     0,    47,   211,   212,    49,   213,    51,    52,   214,
      53,   215,   216,     0,     4,   217,   218,     0,     5,   277,
       0,    55,     0,    56,    57,   219,     8,   220,    59,    60,
     221,    45,     0,    46,     0,     0,    47,   211,   212,    49,
     213,    51,    52,   214,    53,   215,   216,     0,     4,   217,
     218,     0,     5,     0,     0,    55,     0,    56,    57,   219,
       8,   220,    59,    60,   221,    45,     0,    46,     0,     0,
      47,   211,   212,    49,   213,    51,    52,   214,    53,   292,
     293,     0,     4,   217,   218,     0,     5,   302,     0,    55,
       0,    56,    57,   219,     8,   220,    59,    60,    45,     0,
      46,     0,     0,    47,   211,   212,    49,   213,    51,    52,
     214,    53,   292,   293,     0,     4,   217,   218,     0,     5,
     312,     0,    55,     0,    56,    57,   219,     8,   220,    59,
      60,    45,     0,    46,     0,     0,    47,   211,   212,    49,
     213,    51,    52,   214,    53,   292,   293,     0,     4,   217,
     218,     0,     5,     0,     0,    55,     0,    56,    57,   219,
       8,   220,    59,    60,    45,     0,    46,    65,     0,    47,
      48,     0,    49,    50,    51,    52,     0,    53,     0,     0,
       0,     4,    54,    66,     0,     5,     0,    67,    55,     0,
      56,    57,     0,     8,    58,    59,    60,    45,     0,    46,
      65,     0,    47,    48,     0,    49,    50,    51,    52,     0,
      53,     0,     0,     0,     4,    54,    66,     0,     5,     0,
     102,    55,     0,    56,    57,     0,     8,    58,    59,    60,
      45,     0,    46,    65,     0,    47,    48,     0,    49,    50,
      51,    52,     0,    53,     0,     0,     0,     4,    54,    66,
       0,     5,     0,   209,    55,     0,    56,    57,     0,     8,
      58,    59,    60,    45,    75,    46,     0,     0,    47,    48,
       0,    49,    50,    51,    52,     0,    53,     0,     0,     0,
       4,    54,    99,     0,     5,     0,     0,    55,     0,    56,
      57,     0,     8,    58,    59,    60,    45,     0,    46,    65,
       0,    47,    48,     0,    49,    50,    51,    52,     0,    53,
       0,     0,     0,     4,    54,    66,     0,     5,     0,     0,
      55,     0,    56,    57,     0,     8,    58,    59,    60,    45,
       0,    46,     0,     0,    47,    48,     0,    49,    50,    51,
      52,     0,    53,     0,     0,     0,     4,    54,    66,     0,
       5,     0,     0,    55,   171,    56,    57,     0,     8,    58,
      59,    60,    45,     0,    46,     0,     0,    47,    48,     0,
      49,    50,    51,    52,     0,    53,   263,     0,     0,     4,
      54,    66,     0,     5,     0,     0,    55,     0,    56,    57,
       0,     8,    58,    59,    60,    45,     0,    46,     0,     0,
      47,    48,     0,    49,    50,    51,    52,     0,    53,     0,
       0,     0,     4,    54,    66,     0,     5,     0,     0,    55,
       0,    56,    57,     0,     8,    58,    59,    60,    45,     0,
      46,     0,     0,    47,    48,     0,    49,    50,    51,    52,
       0,    53,     0,     0,     0,     4,    54,     0,     0,     5,
       0,     0,    55,     0,    56,    57,     0,     8,    58,    59,
      60
};

static const yytype_int16 yycheck[] =
{
       0,    68,    15,   215,     2,    42,    77,   107,   195,   144,
       0,    11,   100,   192,    96,    31,     5,     0,    25,     7,
     165,    11,   173,    39,    95,    38,    39,    40,    41,   164,
      43,    44,   263,    22,   116,     7,   118,   137,    22,   190,
      21,   272,   187,   188,     7,   257,    17,   234,    21,    21,
     121,   238,   123,    90,    91,   126,    93,   283,   237,   130,
      97,   149,    75,    29,   215,    42,   292,    65,    34,   281,
     301,    84,    85,    86,    87,    88,    89,   292,   304,   167,
     168,     7,     0,    23,    10,    98,    99,    27,    65,   304,
     316,   104,   105,    11,    29,    35,    14,    21,    39,    34,
     113,   316,   169,    21,    21,    23,   257,    29,   108,    27,
      10,   124,    34,    90,    91,    33,    34,    35,    29,    31,
      97,    22,    34,    34,   101,   138,     6,   127,     8,   106,
     281,   183,   283,   146,   186,   112,    16,   114,   115,    19,
     117,   292,   119,    21,   144,    29,   159,     5,   125,   162,
      34,   128,    32,   304,    29,   132,   133,    37,    38,    34,
       5,    21,    23,   176,   164,   316,    27,   157,    29,    22,
      21,    10,    34,   173,    35,     8,   153,     3,   155,    21,
     193,     5,    26,    16,    30,   198,    19,     5,    26,    25,
     190,     5,   205,   170,    29,   185,     4,    10,    28,    32,
      33,    26,   192,   216,    37,    38,    11,    29,   221,    14,
     200,     5,     5,   147,    12,   215,    21,    15,    23,    17,
     233,    11,    27,   288,   134,   210,    24,    25,    33,    34,
      35,   138,    30,   190,   259,   127,   249,   306,    36,   159,
     253,   273,   251,     6,   189,     8,   259,   237,    11,   185,
     263,    14,    15,    16,    17,   268,    19,   257,    99,   272,
      23,   251,    25,    -1,    27,   242,    -1,    30,    -1,    32,
      33,    -1,    35,    23,    37,    38,    -1,    27,    -1,    29,
     293,   281,    -1,   283,    -1,    35,   299,    -1,   301,    -1,
      -1,    -1,   292,   306,    -1,    -1,    -1,     3,    -1,    -1,
       6,    -1,     8,    -1,   304,    11,    12,   284,    14,    15,
      16,    17,    -1,    19,    -1,    -1,   316,    23,    24,    25,
      -1,    27,    -1,   300,    30,    -1,    32,    33,    -1,    35,
      36,    37,    38,     6,   311,     8,    -1,    -1,    11,    12,
      13,    14,    15,    16,    17,    18,    19,    20,    21,    -1,
      23,    24,    25,    -1,    27,    28,    -1,    30,    -1,    32,
      33,    34,    35,    36,    37,    38,    39,     6,    -1,     8,
      -1,    -1,    11,    12,    13,    14,    15,    16,    17,    18,
      19,    20,    21,    -1,    23,    24,    25,    -1,    27,    28,
      -1,    30,    -1,    32,    33,    34,    35,    36,    37,    38,
      39,     6,    -1,     8,    -1,    -1,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    -1,    23,    24,
      25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,    34,
      35,    36,    37,    38,    39,     6,    -1,     8,    -1,    -1,
      11,    12,    13,    14,    15,    16,    17,    18,    19,    20,
      21,    -1,    23,    24,    25,    -1,    27,    28,    -1,    30,
      -1,    32,    33,    34,    35,    36,    37,    38,     6,    -1,
       8,    -1,    -1,    11,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    -1,    23,    24,    25,    -1,    27,
      28,    -1,    30,    -1,    32,    33,    34,    35,    36,    37,
      38,     6,    -1,     8,    -1,    -1,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    -1,    23,    24,
      25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,    34,
      35,    36,    37,    38,     6,    -1,     8,     9,    -1,    11,
      12,    -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,
      -1,    23,    24,    25,    -1,    27,    -1,    29,    30,    -1,
      32,    33,    -1,    35,    36,    37,    38,     6,    -1,     8,
       9,    -1,    11,    12,    -1,    14,    15,    16,    17,    -1,
      19,    -1,    -1,    -1,    23,    24,    25,    -1,    27,    -1,
      29,    30,    -1,    32,    33,    -1,    35,    36,    37,    38,
       6,    -1,     8,     9,    -1,    11,    12,    -1,    14,    15,
      16,    17,    -1,    19,    -1,    -1,    -1,    23,    24,    25,
      -1,    27,    -1,    29,    30,    -1,    32,    33,    -1,    35,
      36,    37,    38,     6,     7,     8,    -1,    -1,    11,    12,
      -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,
      23,    24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,
      33,    -1,    35,    36,    37,    38,     6,    -1,     8,     9,
      -1,    11,    12,    -1,    14,    15,    16,    17,    -1,    19,
      -1,    -1,    -1,    23,    24,    25,    -1,    27,    -1,    -1,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,    -1,    -1,    11,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    24,    25,    -1,
      27,    -1,    -1,    30,    31,    32,    33,    -1,    35,    36,
      37,    38,     6,    -1,     8,    -1,    -1,    11,    12,    -1,
      14,    15,    16,    17,    -1,    19,    20,    -1,    -1,    23,
      24,    25,    -1,    27,    -1,    -1,    30,    -1,    32,    33,
      -1,    35,    36,    37,    38,     6,    -1,     8,    -1,    -1,
      11,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    24,    25,    -1,    27,    -1,    -1,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38,     6,    -1,
       8,    -1,    -1,    11,    12,    -1,    14,    15,    16,    17,
      -1,    19,    -1,    -1,    -1,    23,    24,    -1,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,    37,
      38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_uint8 yystos[] =
{
       0,    11,    14,    21,    23,    27,    33,    34,    35,    41,
      42,    43,    44,    45,    46,    47,    88,    92,    93,    97,
      98,    99,   100,   101,   111,   114,   115,   118,   119,   122,
     123,   124,   125,   126,   127,   128,   129,   130,     8,    16,
      19,    32,    33,    37,    38,     6,     8,    11,    12,    14,
      15,    16,    17,    19,    24,    30,    32,    33,    36,    37,
      38,    47,    84,    85,    89,     9,    25,    29,    53,    54,
      57,    83,    85,    86,    87,     7,    80,    81,    82,     0,
      44,    48,    83,     6,     8,    16,    19,    32,    37,    38,
      83,    83,    83,    83,    80,    81,    83,    83,    25,    25,
      80,    85,    29,    54,     5,    22,    58,    83,    21,    94,
      82,    22,    49,     7,    83,    83,    83,    83,    83,    83,
      80,    81,    80,    81,    17,   102,    81,    21,   102,    80,
      81,    83,   131,   131,    21,    55,    80,    83,    59,    60,
      83,    80,    58,    47,    95,    96,    39,    50,    51,    80,
      83,    80,    80,   102,    80,   102,    80,    21,    21,     3,
      83,   103,   104,    80,    95,    80,    10,    80,    80,    53,
      58,    31,    60,     5,    55,    56,     5,    29,    96,    83,
      31,    51,    55,    22,   107,    21,    21,    80,    80,    10,
      99,   116,   117,    99,   105,   106,    83,   103,     3,    83,
      21,   109,    29,   109,    26,   112,   113,    55,    55,    29,
      80,    12,    13,    15,    18,    20,    21,    24,    25,    34,
      36,    39,    47,    61,    63,    64,    65,    66,    70,    71,
      72,    84,    83,     5,   106,    30,   120,   117,   106,   109,
     109,   113,    70,    29,   116,    83,    29,   105,    83,    99,
     108,   110,    83,    26,    56,    28,    63,    67,    73,    74,
      75,    83,    83,    20,    83,    90,    91,    31,    25,    29,
      29,    80,     5,    83,    29,   108,    83,    28,    63,    29,
      75,     5,    90,    10,    52,     4,    83,   121,    90,   107,
      63,    28,    20,    21,    61,    62,    68,    76,    80,    26,
      52,     5,    28,    62,    69,    77,    78,    79,    83,    83,
      80,    90,    28,    62,    29,    79,     5,    80,    62
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_uint8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    44,    44,    44,    45,
      45,    46,    46,    46,    47,    47,    47,    48,    48,    49,
      49,    50,    50,    51,    52,    52,    53,    53,    54,    54,
      54,    55,    56,    56,    57,    57,    58,    58,    59,    59,
      60,    61,    61,    61,    61,    61,    61,    61,    62,    62,
      62,    63,    63,    63,    63,    64,    65,    66,    66,    67,
      67,    68,    68,    69,    69,    70,    70,    70,    70,    71,
      72,    73,    73,    74,    74,    75,    76,    77,    77,    78,
      78,    79,    80,    80,    81,    81,    82,    83,    83,    84,
      84,    84,    84,    84,    84,    84,    84,    84,    84,    84,
      84,    85,    85,    85,    85,    85,    85,    86,    87,    87,
      88,    89,    89,    90,    90,    91,    91,    92,    92,    92,
      93,    94,    94,    95,    95,    96,    97,    97,    97,    97,
      97,    97,    98,    99,    99,   100,   101,   102,   102,   102,
     102,   103,   103,   104,   104,   105,   106,   106,   107,   107,
     108,   109,   109,   110,   110,   110,   111,   112,   112,   113,
     113,   114,   115,   116,   117,   117,   118,   119,   120,   120,
     121,   121,   122,   122,   123,   123,   124,   124,   124,   124,
     124,   124,   125,   126,   127,   128,   128,   129,   129,   130,
     130,   131
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     1,     2,     1,     1,     1,     1,
       1,     5,     3,     2,     1,     1,     1,     0,     1,     0,
       3,     1,     2,     6,     0,     2,     1,     2,     1,     1,
       1,     3,     0,     1,     6,     4,     0,     3,     1,     2,
       3,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     2,     2,     3,     1,
       2,     2,     3,     1,     2,     1,     1,     1,     1,     1,
       3,     0,     1,     1,     2,     3,     3,     0,     1,     1,
       2,     3,     0,     1,     1,     2,     3,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     3,     5,     3,
       6,     0,     1,     1,     2,     1,     3,     1,     1,     1,
       3,     0,     3,     1,     2,     3,     1,     1,     1,     1,
       1,     1,     1,     0,     1,     4,     6,     0,     3,     2,
       2,     1,     3,     1,     2,     6,     1,     2,     0,     3,
       6,     0,     3,     0,     1,     2,     6,     0,     1,     2,
       3,     6,     7,     3,     1,     2,     7,     8,     0,     1,
       1,     3,     1,     1,     6,     3,     1,     1,     1,     1,
       1,     1,     4,     6,     6,     6,     4,     7,     4,     7,
       4,     1
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
        yyerror (parser, filename, YY_("syntax error: cannot back up")); \
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
                  Kind, Value, parser, filename); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, VALUE parser, VALUE filename)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  YY_USE (parser);
  YY_USE (filename);
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
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep, VALUE parser, VALUE filename)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep, parser, filename);
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
                 int yyrule, VALUE parser, VALUE filename)
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
                       &yyvsp[(yyi + 1) - (yynrhs)], parser, filename);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule, parser, filename); \
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
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep, VALUE parser, VALUE filename)
{
  YY_USE (yyvaluep);
  YY_USE (parser);
  YY_USE (filename);
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
yyparse (VALUE parser, VALUE filename)
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
      yychar = yylex (&yylval, parser, filename);
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
#line 107 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { rb_ivar_set(parser, rb_intern("@result"), yyvsp[0]); }
#line 1942 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 3: /* document: definitions_list  */
#line 109 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
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
    yyval = MAKE_AST_NODE(Document, 3, line, col, yyvsp[0]);
  }
#line 1959 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 4: /* definitions_list: definition  */
#line 123 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1965 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 5: /* definitions_list: definitions_list definition  */
#line 124 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 1971 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 11: /* operation_definition: operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set  */
#line 136 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                   {
        yyval = MAKE_AST_NODE(OperationDefinition, 7,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-4], 3),
          (RB_TEST(yyvsp[-3]) ? rb_ary_entry(yyvsp[-3], 3) : Qnil),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 1987 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 12: /* operation_definition: LCURLY selection_list RCURLY  */
#line 147 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   {
        yyval = MAKE_AST_NODE(OperationDefinition, 7,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          yyvsp[-1]
        );
      }
#line 2003 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 13: /* operation_definition: LCURLY RCURLY  */
#line 158 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    {
        yyval = MAKE_AST_NODE(OperationDefinition, 7,
          rb_ary_entry(yyvsp[-1], 1),
          rb_ary_entry(yyvsp[-1], 2),
          r_string_query,
          Qnil,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE,
          GraphQL_Language_Nodes_NONE
        );
      }
#line 2019 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 17: /* operation_name_opt: %empty  */
#line 176 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2025 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 19: /* variable_definitions_opt: %empty  */
#line 180 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = GraphQL_Language_Nodes_NONE; }
#line 2031 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 20: /* variable_definitions_opt: LPAREN variable_definitions_list RPAREN  */
#line 181 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                              { yyval = yyvsp[-1]; }
#line 2037 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 21: /* variable_definitions_list: variable_definition  */
#line 184 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2043 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 22: /* variable_definitions_list: variable_definitions_list variable_definition  */
#line 185 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 2049 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 23: /* variable_definition: VAR_SIGN name COLON type default_value_opt directives_list_opt  */
#line 188 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                     {
        yyval = MAKE_AST_NODE(VariableDefinition, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2064 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 24: /* default_value_opt: %empty  */
#line 200 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = Qnil; }
#line 2070 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 25: /* default_value_opt: EQUALS literal_value  */
#line 201 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                            { yyval = yyvsp[0]; }
#line 2076 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 26: /* selection_list: selection  */
#line 204 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2082 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 27: /* selection_list: selection_list selection  */
#line 205 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2088 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 31: /* selection_set: LCURLY selection_list RCURLY  */
#line 213 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                   { yyval = yyvsp[-1]; }
#line 2094 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 32: /* selection_set_opt: %empty  */
#line 216 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = rb_ary_new(); }
#line 2100 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 34: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 220 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                        {
      yyval = MAKE_AST_NODE(Field, 7,
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        rb_ary_entry(yyvsp[-5], 3), // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 2116 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 35: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 231 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      yyval = MAKE_AST_NODE(Field, 7,
        rb_ary_entry(yyvsp[-3], 1),
        rb_ary_entry(yyvsp[-3], 2),
        Qnil, // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 2132 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 36: /* arguments_opt: %empty  */
#line 244 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = GraphQL_Language_Nodes_NONE; }
#line 2138 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 37: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 245 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = yyvsp[-1]; }
#line 2144 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 38: /* arguments_list: argument  */
#line 248 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2150 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 39: /* arguments_list: arguments_list argument  */
#line 249 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { rb_ary_push(yyval, yyvsp[0]); }
#line 2156 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 40: /* argument: name COLON input_value  */
#line 252 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(Argument, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2169 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 41: /* scalar_value: FLOAT  */
#line 262 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_f"), 0); }
#line 2175 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 42: /* scalar_value: INT  */
#line 263 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_i"), 0); }
#line 2181 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 43: /* scalar_value: STRING  */
#line 264 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                  { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2187 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 44: /* scalar_value: TRUE_LITERAL  */
#line 265 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qtrue; }
#line 2193 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 45: /* scalar_value: FALSE_LITERAL  */
#line 266 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          { yyval = Qfalse; }
#line 2199 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 55: /* null_value: NULL_LITERAL  */
#line 281 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                           {
    yyval = MAKE_AST_NODE(NullValue, 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2211 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 56: /* variable: VAR_SIGN name  */
#line 289 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                          {
    yyval = MAKE_AST_NODE(VariableIdentifier, 3,
      rb_ary_entry(yyvsp[-1], 1),
      rb_ary_entry(yyvsp[-1], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2223 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 57: /* list_value: LBRACKET RBRACKET  */
#line 298 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2229 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 58: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 299 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[-1]; }
#line 2235 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 59: /* list_value_list: input_value  */
#line 302 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2241 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 60: /* list_value_list: list_value_list input_value  */
#line 303 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 2247 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 61: /* list_literal_value: LBRACKET RBRACKET  */
#line 306 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2253 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 62: /* list_literal_value: LBRACKET list_literal_value_list RBRACKET  */
#line 307 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = yyvsp[-1]; }
#line 2259 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 63: /* list_literal_value_list: literal_value  */
#line 310 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2265 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 64: /* list_literal_value_list: list_literal_value_list literal_value  */
#line 311 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2271 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 69: /* enum_value: enum_name  */
#line 319 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        {
    yyval = MAKE_AST_NODE(Enum, 3,
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 2283 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 70: /* object_value: LCURLY object_value_list_opt RCURLY  */
#line 328 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
      yyval = MAKE_AST_NODE(InputObject, 3,
        rb_ary_entry(yyvsp[-2], 1),
        rb_ary_entry(yyvsp[-2], 2),
        yyvsp[-1]
      );
    }
#line 2295 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 71: /* object_value_list_opt: %empty  */
#line 337 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                        { yyval = GraphQL_Language_Nodes_NONE; }
#line 2301 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 73: /* object_value_list: object_value_field  */
#line 341 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2307 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 74: /* object_value_list: object_value_list object_value_field  */
#line 342 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2313 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 75: /* object_value_field: name COLON input_value  */
#line 345 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(Argument, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2326 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 76: /* object_literal_value: LCURLY object_literal_value_list_opt RCURLY  */
#line 356 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
        yyval = MAKE_AST_NODE(InputObject, 3,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          yyvsp[-1]
        );
      }
#line 2338 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 77: /* object_literal_value_list_opt: %empty  */
#line 365 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2344 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 79: /* object_literal_value_list: object_literal_value_field  */
#line 369 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2350 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 80: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 370 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 2356 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 81: /* object_literal_value_field: name COLON literal_value  */
#line 373 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
        yyval = MAKE_AST_NODE(Argument, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 2369 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 82: /* directives_list_opt: %empty  */
#line 384 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = GraphQL_Language_Nodes_NONE; }
#line 2375 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 84: /* directives_list: directive  */
#line 388 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2381 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 85: /* directives_list: directives_list directive  */
#line 389 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 2387 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 86: /* directive: DIR_SIGN name arguments_opt  */
#line 391 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                         {
    yyval = MAKE_AST_NODE(Directive, 4,
      rb_ary_entry(yyvsp[-2], 1),
      rb_ary_entry(yyvsp[-2], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2400 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 107: /* fragment_spread: ELLIPSIS name_without_on directives_list_opt  */
#line 428 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   {
        yyval = MAKE_AST_NODE(FragmentSpread, 4,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0]
        );
      }
#line 2413 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 108: /* inline_fragment: ELLIPSIS ON NamedTypeForCondition directives_list_opt selection_set  */
#line 438 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                          {
        yyval = MAKE_AST_NODE(InlineFragment, 5,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2427 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 109: /* inline_fragment: ELLIPSIS directives_list_opt selection_set  */
#line 447 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                 {
        yyval = MAKE_AST_NODE(InlineFragment, 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2441 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 110: /* fragment_definition: FRAGMENT fragment_name_opt ON NamedTypeForCondition directives_list_opt selection_set  */
#line 458 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                          {
      yyval = MAKE_AST_NODE(FragmentDefinition, 6,
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        yyvsp[-4],
        yyvsp[-2],
        yyvsp[-1],
        yyvsp[0]
      );
    }
#line 2456 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 111: /* fragment_name_opt: %empty  */
#line 470 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = Qnil; }
#line 2462 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 112: /* fragment_name_opt: name_without_on  */
#line 471 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 2468 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 114: /* type: nullable_type BANG  */
#line 475 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              { yyval = MAKE_AST_NODE(NonNullType, 3, rb_funcall(yyvsp[-1], rb_intern("line"), 0), rb_funcall(yyvsp[-1], rb_intern("col"), 0), yyvsp[-1]); }
#line 2474 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 115: /* nullable_type: name  */
#line 478 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 2486 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 116: /* nullable_type: LBRACKET type RBRACKET  */
#line 485 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                             {
        yyval = MAKE_AST_NODE(ListType, 3,
          rb_funcall(yyvsp[-1], rb_intern("line"), 0),
          rb_funcall(yyvsp[-1], rb_intern("col"), 0),
          yyvsp[-1]
        );
      }
#line 2498 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 120: /* schema_definition: SCHEMA directives_list_opt operation_type_definition_list_opt  */
#line 499 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                    {
        yyval = MAKE_AST_NODE(SchemaDefinition, 6,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          // TODO use static strings:
          rb_hash_aref(yyvsp[0], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[0], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[0], rb_str_new_cstr("subscription")),
          yyvsp[-1]
        );
      }
#line 2514 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 121: /* operation_type_definition_list_opt: %empty  */
#line 512 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = rb_hash_new(); }
#line 2520 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 122: /* operation_type_definition_list_opt: LCURLY operation_type_definition_list RCURLY  */
#line 513 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = yyvsp[-1]; }
#line 2526 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 123: /* operation_type_definition_list: operation_type_definition  */
#line 516 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_hash_new();
        rb_hash_aset(yyval, rb_ary_entry(yyvsp[0], 0), rb_ary_entry(yyvsp[0], 1));
      }
#line 2535 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 124: /* operation_type_definition_list: operation_type_definition_list operation_type_definition  */
#line 520 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                               {
      rb_hash_aset(yyval, rb_ary_entry(yyvsp[0], 0), rb_ary_entry(yyvsp[0], 1));
    }
#line 2543 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 125: /* operation_type_definition: operation_type COLON name  */
#line 525 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                {
        yyval = rb_ary_new_from_args(2, rb_ary_entry(yyvsp[-2], 3), rb_ary_entry(yyvsp[0], 3));
      }
#line 2551 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 133: /* description_opt: %empty  */
#line 540 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                      { yyval = Qnil; }
#line 2557 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 135: /* scalar_type_definition: description_opt SCALAR name directives_list_opt  */
#line 544 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                      {
        yyval = MAKE_AST_NODE(ScalarTypeDefinition, 5,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-1], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-3]) ? rb_ary_entry(yyvsp[-3], 3) : Qnil),
          yyvsp[0]
        );
      }
#line 2572 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 136: /* object_type_definition: description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 556 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                     {
        yyval = MAKE_AST_NODE(ObjectTypeDefinition, 7,
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
#line 2589 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 137: /* implements_opt: %empty  */
#line 570 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2595 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 138: /* implements_opt: IMPLEMENTS AMP interfaces_list  */
#line 571 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                     { yyval = yyvsp[0]; }
#line 2601 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 139: /* implements_opt: IMPLEMENTS interfaces_list  */
#line 572 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                 { yyval = yyvsp[0]; }
#line 2607 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 140: /* implements_opt: IMPLEMENTS legacy_interfaces_list  */
#line 573 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        { yyval = yyvsp[0]; }
#line 2613 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 141: /* interfaces_list: name  */
#line 576 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2626 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 142: /* interfaces_list: interfaces_list AMP name  */
#line 584 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                               {
      VALUE new_name =  MAKE_AST_NODE(TypeName, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3));
      rb_ary_push(yyval, new_name);
    }
#line 2635 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 143: /* legacy_interfaces_list: name  */
#line 590 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
           {
        VALUE new_name = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_name);
      }
#line 2648 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 144: /* legacy_interfaces_list: legacy_interfaces_list name  */
#line 598 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                  {
      rb_ary_push(yyval, MAKE_AST_NODE(TypeName, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
    }
#line 2656 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 145: /* input_value_definition: description_opt name COLON type default_value_opt directives_list_opt  */
#line 603 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                            {
        yyval = MAKE_AST_NODE(InputValueDefinition, 7,
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
#line 2673 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 146: /* input_value_definition_list: input_value_definition  */
#line 617 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2679 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 147: /* input_value_definition_list: input_value_definition_list input_value_definition  */
#line 618 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                         { rb_ary_push(yyval, yyvsp[0]); }
#line 2685 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 148: /* arguments_definitions_opt: %empty  */
#line 621 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2691 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 149: /* arguments_definitions_opt: LPAREN input_value_definition_list RPAREN  */
#line 622 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                { yyval = yyvsp[-1]; }
#line 2697 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 150: /* field_definition: description_opt name arguments_definitions_opt COLON type directives_list_opt  */
#line 625 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                    {
        yyval = MAKE_AST_NODE(FieldDefinition, 7,
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
#line 2714 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 151: /* field_definition_list_opt: %empty  */
#line 639 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2720 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 152: /* field_definition_list_opt: LCURLY field_definition_list RCURLY  */
#line 640 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                          { yyval = yyvsp[-1]; }
#line 2726 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 153: /* field_definition_list: %empty  */
#line 643 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                { yyval = GraphQL_Language_Nodes_NONE; }
#line 2732 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 154: /* field_definition_list: field_definition  */
#line 644 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2738 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 155: /* field_definition_list: field_definition_list field_definition  */
#line 645 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                             { rb_ary_push(yyval, yyvsp[0]); }
#line 2744 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 156: /* interface_type_definition: description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 648 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                  {
        yyval = MAKE_AST_NODE(InterfaceTypeDefinition, 7,
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
#line 2761 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 157: /* pipe_opt: %empty  */
#line 662 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                 { yyval = GraphQL_Language_Nodes_NONE; }
#line 2767 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 158: /* pipe_opt: PIPE  */
#line 663 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
               { yyval = GraphQL_Language_Nodes_NONE; }
#line 2773 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 159: /* union_members: pipe_opt name  */
#line 666 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    {
        VALUE new_member = MAKE_AST_NODE(TypeName, 3,
          rb_ary_entry(yyvsp[0], 1),
          rb_ary_entry(yyvsp[0], 2),
          rb_ary_entry(yyvsp[0], 3)
        );
        yyval = rb_ary_new_from_args(1, new_member);
      }
#line 2786 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 160: /* union_members: union_members PIPE name  */
#line 674 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                              {
        rb_ary_push(yyval, MAKE_AST_NODE(TypeName, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3)));
      }
#line 2794 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 161: /* union_type_definition: description_opt UNION name directives_list_opt EQUALS union_members  */
#line 679 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                          {
        yyval = MAKE_AST_NODE(UnionTypeDefinition,  6,
          rb_ary_entry(yyvsp[-4], 1),
          rb_ary_entry(yyvsp[-4], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[0], // types
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-5]) ? rb_ary_entry(yyvsp[-5], 3) : Qnil),
          yyvsp[-2]
        );
      }
#line 2810 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 162: /* enum_type_definition: description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 692 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = MAKE_AST_NODE(EnumTypeDefinition,  6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2826 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 163: /* enum_value_definition: description_opt enum_name directives_list_opt  */
#line 705 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                  {
      yyval = MAKE_AST_NODE(EnumValueDefinition, 5,
        rb_ary_entry(yyvsp[-1], 1),
        rb_ary_entry(yyvsp[-1], 2),
        rb_ary_entry(yyvsp[-1], 3),
        // TODO see get_description for reading a description from comments
        (RB_TEST(yyvsp[-2]) ? rb_ary_entry(yyvsp[-2], 3) : Qnil),
        yyvsp[0]
      );
    }
#line 2841 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 164: /* enum_value_definitions: enum_value_definition  */
#line 717 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 2847 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 165: /* enum_value_definitions: enum_value_definitions enum_value_definition  */
#line 718 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                   { rb_ary_push(yyval, yyvsp[0]); }
#line 2853 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 166: /* input_object_type_definition: description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 721 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                               {
        yyval = MAKE_AST_NODE(InputObjectTypeDefinition, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-4], 3),
          // TODO see get_description for reading a description from comments
          (RB_TEST(yyvsp[-6]) ? rb_ary_entry(yyvsp[-6], 3) : Qnil),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 2869 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 167: /* directive_definition: description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations  */
#line 734 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                                                        {
        yyval = MAKE_AST_NODE(DirectiveDefinition, 7,
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
#line 2886 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 168: /* directive_repeatable_opt: %empty  */
#line 748 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = Qnil; }
#line 2892 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 169: /* directive_repeatable_opt: REPEATABLE  */
#line 749 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                    { yyval = Qtrue; }
#line 2898 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 170: /* directive_locations: name  */
#line 752 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, MAKE_AST_NODE(DirectiveLocation, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2904 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 171: /* directive_locations: directive_locations PIPE name  */
#line 753 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    { rb_ary_push(yyval, MAKE_AST_NODE(DirectiveLocation, 3, rb_ary_entry(yyvsp[0], 1), rb_ary_entry(yyvsp[0], 2), rb_ary_entry(yyvsp[0], 3))); }
#line 2910 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 174: /* schema_extension: EXTEND SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 761 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                     {
        yyval = MAKE_AST_NODE(SchemaExtension, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          // TODO use static strings:
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("query")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("mutation")),
          rb_hash_aref(yyvsp[-1], rb_str_new_cstr("subscription")),
          yyvsp[-3]
        );
      }
#line 2926 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 175: /* schema_extension: EXTEND SCHEMA directives_list  */
#line 772 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                    {
        yyval = MAKE_AST_NODE(SchemaExtension, 6,
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          Qnil,
          Qnil,
          Qnil,
          yyvsp[0]
        );
      }
#line 2941 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 182: /* scalar_type_extension: EXTEND SCALAR name directives_list  */
#line 791 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                            {
    yyval = MAKE_AST_NODE(ScalarTypeExtension, 4,
      rb_ary_entry(yyvsp[-3], 1),
      rb_ary_entry(yyvsp[-3], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 2954 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 183: /* object_type_extension: EXTEND TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 801 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                            {
        yyval = MAKE_AST_NODE(ObjectTypeExtension, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2], // implements
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2969 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 184: /* interface_type_extension: EXTEND INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 813 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                         {
        yyval = MAKE_AST_NODE(InterfaceTypeExtension, 6,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[-2],
          yyvsp[-1],
          yyvsp[0]
        );
      }
#line 2984 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 185: /* union_type_extension: EXTEND UNION name directives_list_opt EQUALS union_members  */
#line 825 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                 {
        yyval = MAKE_AST_NODE(UnionTypeExtension, 5,
          rb_ary_entry(yyvsp[-5], 1),
          rb_ary_entry(yyvsp[-5], 2),
          rb_ary_entry(yyvsp[-3], 3),
          yyvsp[0], // types
          yyvsp[-2]
        );
      }
#line 2998 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 186: /* union_type_extension: EXTEND UNION name directives_list  */
#line 834 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
        yyval = MAKE_AST_NODE(UnionTypeExtension, 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          GraphQL_Language_Nodes_NONE, // types
          yyvsp[0]
        );
      }
#line 3012 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 187: /* enum_type_extension: EXTEND ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 845 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                {
        yyval = MAKE_AST_NODE(EnumTypeExtension, 5,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 3026 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 188: /* enum_type_extension: EXTEND ENUM name directives_list  */
#line 854 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                       {
        yyval = MAKE_AST_NODE(EnumTypeExtension, 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0],
          GraphQL_Language_Nodes_NONE
        );
      }
#line 3040 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 189: /* input_object_type_extension: EXTEND INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 865 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                                                                      {
        yyval = MAKE_AST_NODE(InputObjectTypeExtension, 5,
          rb_ary_entry(yyvsp[-6], 1),
          rb_ary_entry(yyvsp[-6], 2),
          rb_ary_entry(yyvsp[-4], 3),
          yyvsp[-3],
          yyvsp[-1]
        );
      }
#line 3054 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 190: /* input_object_type_extension: EXTEND INPUT name directives_list  */
#line 874 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
                                        {
        yyval = MAKE_AST_NODE(InputObjectTypeExtension, 5,
          rb_ary_entry(yyvsp[-3], 1),
          rb_ary_entry(yyvsp[-3], 2),
          rb_ary_entry(yyvsp[-1], 3),
          yyvsp[0],
          GraphQL_Language_Nodes_NONE
        );
      }
#line 3068 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;

  case 191: /* NamedTypeForCondition: name  */
#line 886 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"
          {
              /* This action creates a TypeName AST node.
                 $1 (yyvsp[0] in C) refers to the semantic value of 'name'.
                 The MAKE_AST_NODE macro is used, consistent with other rules.
                 'name' (represented by $1) provides an array: [filename, line, col, name_string] */
              yyval = MAKE_AST_NODE(TypeName, 3,
                                 rb_ary_entry(yyvsp[0], 1), /* line from name token */
                                 rb_ary_entry(yyvsp[0], 2), /* col from name token */
                                 rb_ary_entry(yyvsp[0], 3)  /* name string itself */
                                );
          }
#line 3084 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"
    break;


#line 3088 "graphql-c_parser/ext/graphql_c_parser_ext/parser.c"

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
        yyerror (parser, filename, yymsgp);
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
                      yytoken, &yylval, parser, filename);
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
                  YY_ACCESSING_SYMBOL (yystate), yyvsp, parser, filename);
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
  yyerror (parser, filename, YY_("memory exhausted"));
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
                  yytoken, &yylval, parser, filename);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp, parser, filename);
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

#line 899 "graphql-c_parser/ext/graphql_c_parser_ext/parser.y"


// Custom functions
int yylex (YYSTYPE *lvalp, VALUE parser, VALUE filename) {
  VALUE next_token_idx_rb_int = rb_ivar_get(parser, rb_intern("@next_token_index"));
  int next_token_idx = FIX2INT(next_token_idx_rb_int);
  VALUE tokens = rb_ivar_get(parser, rb_intern("@tokens"));
  VALUE next_token = rb_ary_entry(tokens, next_token_idx);

  if (!RB_TEST(next_token)) {
    return YYEOF;
  }
  rb_ivar_set(parser, rb_intern("@next_token_index"), INT2FIX(next_token_idx + 1));
  VALUE token_type_rb_int = rb_ary_entry(next_token, 4);
  int next_token_type = FIX2INT(token_type_rb_int);
  if (next_token_type == 241) { // BAD_UNICODE_ESCAPE
    VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
    VALUE mCParser = rb_const_get_at(mGraphQL, rb_intern("CParser"));
    VALUE bad_unicode_error = rb_funcall(
        mCParser, rb_intern("prepare_bad_unicode_error"), 1,
        parser
    );
    rb_exc_raise(bad_unicode_error);
  }
  *lvalp = next_token;
  return next_token_type;
}

void yyerror(VALUE parser, VALUE filename, const char *msg) {
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

#define INITIALIZE_NODE_CLASS_VARIABLE(node_class_name) \
    rb_global_variable(&GraphQL_Language_Nodes_##node_class_name); \
    GraphQL_Language_Nodes_##node_class_name = rb_const_get_at(mGraphQLLanguageNodes, rb_intern(#node_class_name));

void initialize_node_class_variables(void) {
  VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
  VALUE mGraphQLLanguage = rb_const_get_at(mGraphQL, rb_intern("Language"));
  VALUE mGraphQLLanguageNodes = rb_const_get_at(mGraphQLLanguage, rb_intern("Nodes"));

  rb_global_variable(&GraphQL_Language_Nodes_NONE);
  GraphQL_Language_Nodes_NONE = rb_ary_new();
  rb_ary_freeze(GraphQL_Language_Nodes_NONE);

  rb_global_variable(&r_string_query);
  r_string_query = rb_str_new_cstr("query");
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
