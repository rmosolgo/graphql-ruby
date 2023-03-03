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
#line 4 "ext/graphql_ext/parser.y"

// C Declarations
#include <ruby.h>
union YYSTYPE;
int yylex(union YYSTYPE *);

#line 78 "ext/graphql_ext/parser.c"

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
    AMP = 258,                     /* AMP  */
    BANG = 259,                    /* BANG  */
    COLON = 260,                   /* COLON  */
    DIRECTIVE = 261,               /* DIRECTIVE  */
    DIR_SIGN = 262,                /* DIR_SIGN  */
    ENUM = 263,                    /* ENUM  */
    ELLIPSIS = 264,                /* ELLIPSIS  */
    EQUALS = 265,                  /* EQUALS  */
    EXTEND = 266,                  /* EXTEND  */
    FALSE_LITERAL = 267,           /* FALSE_LITERAL  */
    FLOAT = 268,                   /* FLOAT  */
    FRAGMENT = 269,                /* FRAGMENT  */
    IDENTIFIER = 270,              /* IDENTIFIER  */
    INPUT = 271,                   /* INPUT  */
    IMPLEMENTS = 272,              /* IMPLEMENTS  */
    INT = 273,                     /* INT  */
    INTERFACE = 274,               /* INTERFACE  */
    LBRACKET = 275,                /* LBRACKET  */
    LCURLY = 276,                  /* LCURLY  */
    LPAREN = 277,                  /* LPAREN  */
    MUTATION = 278,                /* MUTATION  */
    NULL_LITERAL = 279,            /* NULL_LITERAL  */
    ON = 280,                      /* ON  */
    PIPE = 281,                    /* PIPE  */
    QUERY = 282,                   /* QUERY  */
    RBRACKET = 283,                /* RBRACKET  */
    RCURLY = 284,                  /* RCURLY  */
    REPEATABLE = 285,              /* REPEATABLE  */
    RPAREN = 286,                  /* RPAREN  */
    SCALAR = 287,                  /* SCALAR  */
    SCHEMA = 288,                  /* SCHEMA  */
    STRING = 289,                  /* STRING  */
    SUBSCRIPTION = 290,            /* SUBSCRIPTION  */
    TRUE_LITERAL = 291,            /* TRUE_LITERAL  */
    TYPE_LITERAL = 292,            /* TYPE_LITERAL  */
    UNION = 293,                   /* UNION  */
    VAR_SIGN = 294                 /* VAR_SIGN  */
  };
  typedef enum yytokentype yytoken_kind_t;
#endif
/* Token kinds.  */
#define YYEMPTY -2
#define YYEOF 0
#define YYerror 256
#define YYUNDEF 257
#define AMP 258
#define BANG 259
#define COLON 260
#define DIRECTIVE 261
#define DIR_SIGN 262
#define ENUM 263
#define ELLIPSIS 264
#define EQUALS 265
#define EXTEND 266
#define FALSE_LITERAL 267
#define FLOAT 268
#define FRAGMENT 269
#define IDENTIFIER 270
#define INPUT 271
#define IMPLEMENTS 272
#define INT 273
#define INTERFACE 274
#define LBRACKET 275
#define LCURLY 276
#define LPAREN 277
#define MUTATION 278
#define NULL_LITERAL 279
#define ON 280
#define PIPE 281
#define QUERY 282
#define RBRACKET 283
#define RCURLY 284
#define REPEATABLE 285
#define RPAREN 286
#define SCALAR 287
#define SCHEMA 288
#define STRING 289
#define SUBSCRIPTION 290
#define TRUE_LITERAL 291
#define TYPE_LITERAL 292
#define UNION 293
#define VAR_SIGN 294

/* Value type.  */
#if ! defined YYSTYPE && ! defined YYSTYPE_IS_DECLARED
typedef int YYSTYPE;
# define YYSTYPE_IS_TRIVIAL 1
# define YYSTYPE_IS_DECLARED 1
#endif




int yyparse (void);



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
  YYSYMBOL_type = 52,                      /* type  */
  YYSYMBOL_nullable_type = 53,             /* nullable_type  */
  YYSYMBOL_default_value_opt = 54,         /* default_value_opt  */
  YYSYMBOL_selection_set = 55,             /* selection_set  */
  YYSYMBOL_selection_set_opt = 56,         /* selection_set_opt  */
  YYSYMBOL_selection_list = 57,            /* selection_list  */
  YYSYMBOL_selection = 58,                 /* selection  */
  YYSYMBOL_field = 59,                     /* field  */
  YYSYMBOL_name = 60,                      /* name  */
  YYSYMBOL_schema_keyword = 61,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 62,           /* name_without_on  */
  YYSYMBOL_enum_name = 63,                 /* enum_name  */
  YYSYMBOL_enum_value_definition = 64,     /* enum_value_definition  */
  YYSYMBOL_enum_value_definitions = 65,    /* enum_value_definitions  */
  YYSYMBOL_arguments_opt = 66,             /* arguments_opt  */
  YYSYMBOL_arguments_list = 67,            /* arguments_list  */
  YYSYMBOL_argument = 68,                  /* argument  */
  YYSYMBOL_literal_value = 69,             /* literal_value  */
  YYSYMBOL_input_value = 70,               /* input_value  */
  YYSYMBOL_null_value = 71,                /* null_value  */
  YYSYMBOL_variable = 72,                  /* variable  */
  YYSYMBOL_list_value = 73,                /* list_value  */
  YYSYMBOL_list_value_list = 74,           /* list_value_list  */
  YYSYMBOL_object_value = 75,              /* object_value  */
  YYSYMBOL_object_value_list = 76,         /* object_value_list  */
  YYSYMBOL_object_value_field = 77,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 78,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list = 79, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 80, /* object_literal_value_field  */
  YYSYMBOL_enum_value = 81,                /* enum_value  */
  YYSYMBOL_directives_list_opt = 82,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 83,           /* directives_list  */
  YYSYMBOL_directive = 84,                 /* directive  */
  YYSYMBOL_fragment_spread = 85,           /* fragment_spread  */
  YYSYMBOL_inline_fragment = 86,           /* inline_fragment  */
  YYSYMBOL_fragment_definition = 87,       /* fragment_definition  */
  YYSYMBOL_fragment_name_opt = 88,         /* fragment_name_opt  */
  YYSYMBOL_type_system_definition = 89,    /* type_system_definition  */
  YYSYMBOL_schema_definition = 90,         /* schema_definition  */
  YYSYMBOL_operation_type_definition_list = 91, /* operation_type_definition_list  */
  YYSYMBOL_operation_type_definition = 92, /* operation_type_definition  */
  YYSYMBOL_type_definition = 93,           /* type_definition  */
  YYSYMBOL_type_system_extension = 94,     /* type_system_extension  */
  YYSYMBOL_schema_extension = 95,          /* schema_extension  */
  YYSYMBOL_type_extension = 96,            /* type_extension  */
  YYSYMBOL_scalar_type_extension = 97,     /* scalar_type_extension  */
  YYSYMBOL_object_type_extension = 98,     /* object_type_extension  */
  YYSYMBOL_interface_type_extension = 99,  /* interface_type_extension  */
  YYSYMBOL_union_type_extension = 100,     /* union_type_extension  */
  YYSYMBOL_enum_type_extension = 101,      /* enum_type_extension  */
  YYSYMBOL_input_object_type_extension = 102, /* input_object_type_extension  */
  YYSYMBOL_description = 103,              /* description  */
  YYSYMBOL_description_opt = 104,          /* description_opt  */
  YYSYMBOL_scalar_type_definition = 105,   /* scalar_type_definition  */
  YYSYMBOL_object_type_definition = 106,   /* object_type_definition  */
  YYSYMBOL_implements_opt = 107,           /* implements_opt  */
  YYSYMBOL_implements = 108,               /* implements  */
  YYSYMBOL_interfaces_list = 109,          /* interfaces_list  */
  YYSYMBOL_legacy_interfaces_list = 110,   /* legacy_interfaces_list  */
  YYSYMBOL_input_value_definition = 111,   /* input_value_definition  */
  YYSYMBOL_input_value_definition_list = 112, /* input_value_definition_list  */
  YYSYMBOL_arguments_definitions_opt = 113, /* arguments_definitions_opt  */
  YYSYMBOL_field_definition = 114,         /* field_definition  */
  YYSYMBOL_field_definition_list_opt = 115, /* field_definition_list_opt  */
  YYSYMBOL_field_definition_list = 116,    /* field_definition_list  */
  YYSYMBOL_interface_type_definition = 117, /* interface_type_definition  */
  YYSYMBOL_union_members = 118,            /* union_members  */
  YYSYMBOL_union_type_definition = 119,    /* union_type_definition  */
  YYSYMBOL_enum_type_definition = 120,     /* enum_type_definition  */
  YYSYMBOL_input_object_type_definition = 121, /* input_object_type_definition  */
  YYSYMBOL_directive_definition = 122,     /* directive_definition  */
  YYSYMBOL_directive_repeatable_opt = 123, /* directive_repeatable_opt  */
  YYSYMBOL_directive_locations = 124       /* directive_locations  */
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

#if !defined yyoverflow

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
#endif /* !defined yyoverflow */

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
#define YYLAST   946

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  85
/* YYNRULES -- Number of rules.  */
#define YYNRULES  184
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  315

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   294


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
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    22,    23,    24,
      25,    26,    27,    28,    29,    30,    31,    32,    33,    34,
      35,    36,    37,    38,    39
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,    54,    54,    56,    59,    60,    63,    64,    65,    68,
      69,    72,    84,    93,   104,   105,   106,   109,   110,   113,
     114,   117,   118,   121,   131,   132,   135,   136,   139,   140,
     143,   146,   147,   150,   151,   154,   155,   156,   159,   170,
     184,   185,   188,   189,   190,   191,   192,   193,   194,   195,
     196,   199,   200,   201,   202,   203,   204,   205,   208,   209,
     210,   211,   212,   213,   216,   219,   220,   223,   224,   227,
     228,   231,   234,   235,   236,   237,   238,   239,   240,   241,
     242,   245,   246,   247,   249,   250,   253,   254,   257,   258,
     261,   262,   265,   266,   269,   273,   274,   277,   278,   281,
     283,   286,   287,   290,   291,   293,   296,   299,   307,   317,
     329,   330,   333,   334,   335,   338,   341,   342,   345,   348,
     349,   350,   351,   352,   353,   356,   357,   360,   361,   364,
     365,   366,   367,   368,   369,   371,   375,   376,   377,   378,
     381,   382,   383,   386,   387,   390,   391,   394,   395,   397,
     399,   401,   404,   409,   414,   415,   418,   419,   420,   423,
     424,   427,   428,   431,   436,   437,   440,   441,   444,   449,
     450,   453,   454,   455,   458,   463,   464,   467,   472,   477,
     482,   486,   488,   491,   492
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "AMP", "BANG", "COLON",
  "DIRECTIVE", "DIR_SIGN", "ENUM", "ELLIPSIS", "EQUALS", "EXTEND",
  "FALSE_LITERAL", "FLOAT", "FRAGMENT", "IDENTIFIER", "INPUT",
  "IMPLEMENTS", "INT", "INTERFACE", "LBRACKET", "LCURLY", "LPAREN",
  "MUTATION", "NULL_LITERAL", "ON", "PIPE", "QUERY", "RBRACKET", "RCURLY",
  "REPEATABLE", "RPAREN", "SCALAR", "SCHEMA", "STRING", "SUBSCRIPTION",
  "TRUE_LITERAL", "TYPE_LITERAL", "UNION", "VAR_SIGN", "$accept", "start",
  "document", "definitions_list", "definition", "executable_definition",
  "operation_definition", "operation_type", "operation_name_opt",
  "variable_definitions_opt", "variable_definitions_list",
  "variable_definition", "type", "nullable_type", "default_value_opt",
  "selection_set", "selection_set_opt", "selection_list", "selection",
  "field", "name", "schema_keyword", "name_without_on", "enum_name",
  "enum_value_definition", "enum_value_definitions", "arguments_opt",
  "arguments_list", "argument", "literal_value", "input_value",
  "null_value", "variable", "list_value", "list_value_list",
  "object_value", "object_value_list", "object_value_field",
  "object_literal_value", "object_literal_value_list",
  "object_literal_value_field", "enum_value", "directives_list_opt",
  "directives_list", "directive", "fragment_spread", "inline_fragment",
  "fragment_definition", "fragment_name_opt", "type_system_definition",
  "schema_definition", "operation_type_definition_list",
  "operation_type_definition", "type_definition", "type_system_extension",
  "schema_extension", "type_extension", "scalar_type_extension",
  "object_type_extension", "interface_type_extension",
  "union_type_extension", "enum_type_extension",
  "input_object_type_extension", "description", "description_opt",
  "scalar_type_definition", "object_type_definition", "implements_opt",
  "implements", "interfaces_list", "legacy_interfaces_list",
  "input_value_definition", "input_value_definition_list",
  "arguments_definitions_opt", "field_definition",
  "field_definition_list_opt", "field_definition_list",
  "interface_type_definition", "union_members", "union_type_definition",
  "enum_type_definition", "input_object_type_definition",
  "directive_definition", "directive_repeatable_opt",
  "directive_locations", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-266)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-172)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     245,   210,   875,   479,  -266,  -266,    14,  -266,  -266,    22,
    -266,   211,  -266,  -266,  -266,   842,  -266,  -266,  -266,  -266,
    -266,  -266,  -266,  -266,  -266,  -266,  -266,  -266,  -266,  -266,
      85,  -266,  -266,  -266,  -266,  -266,  -266,  -266,   842,   842,
     842,   842,    14,   842,   842,  -266,  -266,  -266,  -266,  -266,
    -266,  -266,  -266,  -266,  -266,  -266,  -266,  -266,  -266,  -266,
    -266,  -266,     9,   578,  -266,  -266,   512,  -266,  -266,     3,
    -266,  -266,  -266,   842,    37,    14,  -266,  -266,  -266,    45,
    -266,    61,   842,   842,   842,   842,   842,   842,    14,    14,
      60,    14,    66,    12,    60,    14,   611,   611,    14,    67,
    -266,  -266,   842,   842,    14,    74,   101,  -266,    86,    14,
     842,    14,    14,    60,    14,    60,    14,    92,    12,   110,
      12,   311,    14,   125,    14,   101,    14,    55,   128,    21,
     611,    14,   144,  -266,    14,  -266,   644,  -266,    74,   147,
     677,  -266,    67,  -266,   150,   160,  -266,   842,    -7,  -266,
      67,   134,   142,   143,    14,  -266,  -266,    14,   158,   136,
     136,   842,    91,   168,   842,   152,    14,   192,   152,    14,
      40,  -266,   842,   151,    67,  -266,    67,   545,    14,   412,
    -266,  -266,  -266,  -266,   842,  -266,  -266,   173,  -266,  -266,
    -266,   136,   156,   136,   136,   152,   152,   842,  -266,    80,
     908,   842,  -266,    81,  -266,   168,   842,  -266,  -266,  -266,
    -266,   842,  -266,   105,  -266,   154,  -266,  -266,  -266,  -266,
      67,  -266,  -266,  -266,  -266,  -266,   344,   710,  -266,  -266,
    -266,  -266,  -266,   842,  -266,  -266,  -266,  -266,  -266,  -266,
    -266,  -266,  -266,  -266,  -266,  -266,   611,    16,  -266,   157,
     117,   120,  -266,  -266,   154,  -266,  -266,    14,   185,  -266,
    -266,  -266,   134,  -266,  -266,   842,  -266,  -266,  -266,   378,
    -266,   186,   743,  -266,   776,  -266,  -266,   182,  -266,   842,
    -266,  -266,  -266,   611,   188,  -266,  -266,  -266,   412,  -266,
     194,  -266,  -266,   196,  -266,   446,  -266,  -266,   171,   182,
     611,  -266,  -266,   412,   446,   809,  -266,   842,    14,    14,
    -266,  -266,  -266,  -266,  -266
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] =
{
     150,     0,   110,     0,    15,    14,   101,   149,    16,     0,
       2,   150,     4,     6,     9,    17,    10,     7,   112,   113,
       8,   125,   126,   129,   130,   131,   132,   133,   134,   151,
       0,   119,   120,   121,   122,   123,   124,   114,     0,     0,
       0,     0,   101,     0,     0,    50,    48,    55,    52,    51,
      49,    45,    46,    53,    43,    42,    54,    44,    47,    56,
      57,   111,     0,   101,    41,    13,     0,    33,    35,    67,
      40,    36,    37,     0,     0,   102,   103,     1,     5,    19,
      18,     0,     0,     0,     0,     0,     0,     0,   101,   101,
     154,     0,     0,   128,   154,   101,     0,     0,   101,     0,
      12,    34,     0,     0,   101,    67,     0,   104,     0,   101,
       0,   101,   101,   154,   101,   154,   101,     0,   146,     0,
     148,     0,   101,   142,   135,     0,   101,   139,     0,   144,
       0,   101,    24,    26,   101,   106,     0,   108,    67,     0,
       0,    69,    31,   105,     0,     0,   116,     0,     0,    21,
       0,   166,     0,     0,   101,   155,   152,   101,     0,   150,
     150,     0,   159,   157,   158,   169,   102,     0,   169,   102,
     150,   136,     0,     0,     0,    25,     0,     0,   101,     0,
      68,    70,    32,    38,     0,   115,   117,     0,    20,    22,
      11,   150,   181,   150,   150,   169,   169,     0,    65,   150,
       0,     0,   164,   150,   159,   156,     0,   162,   140,   127,
     137,     0,   172,   150,   175,   143,    27,   109,   107,    30,
      31,    76,    72,    59,    58,    73,     0,     0,    84,    61,
      60,    74,    75,     0,    62,    63,   100,    81,    71,    77,
      82,    79,    83,    80,    78,   118,     0,   150,   182,     0,
     150,   150,   174,   153,   177,   145,    66,   101,     0,   147,
     165,   160,   166,   170,   173,     0,    39,    86,    88,     0,
      90,     0,     0,    92,     0,    97,    85,    28,   167,     0,
     178,   179,    64,     0,     0,   176,    87,    89,     0,    91,
       0,    93,    96,     0,    98,     0,    23,   183,   180,    28,
       0,    81,    94,     0,     0,     0,    29,     0,   101,   101,
      99,    95,   184,   163,   168
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
    -266,  -266,  -266,  -266,   191,  -266,  -266,     5,  -266,  -266,
    -266,    56,   -87,  -266,   -92,   -79,   -10,    76,   -65,  -266,
      -3,  -128,     1,    17,  -184,    23,   -96,  -266,    83,  -265,
    -177,  -266,  -266,  -266,  -266,  -266,  -266,   -58,  -266,  -266,
     -46,  -266,    31,   -36,   -64,  -266,  -266,  -266,  -266,  -266,
    -266,   108,  -141,  -266,  -266,  -266,  -266,  -266,  -266,  -266,
    -266,  -266,  -266,  -266,     7,  -266,  -266,   -67,    -5,    75,
    -266,  -190,  -116,   -27,    24,  -151,  -266,  -266,    42,  -266,
    -266,  -266,  -266,  -266,  -266
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] =
{
       0,     9,    10,    11,    12,    13,    14,    59,    79,   109,
     148,   149,   131,   132,   296,   182,   183,    66,    67,    68,
     133,    60,    70,   236,   198,   199,   104,   140,   141,   237,
     302,   239,   240,   241,   269,   242,   272,   273,   243,   274,
     275,   244,    74,    75,    76,    71,    72,    16,    62,    17,
      18,   145,   146,    19,    20,    21,    22,    23,    24,    25,
      26,    27,    28,    29,   201,    31,    32,   122,   155,   163,
     164,   202,   203,   192,   212,   171,   213,    33,   215,    34,
      35,    36,    37,   249,   298
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int16 yytable[] =
{
      69,   101,   238,    61,   186,    15,    93,    30,   102,   143,
     134,   107,    80,   260,   208,   256,    15,   210,    30,    73,
     137,    73,    77,   301,   188,   103,   186,   126,    73,   107,
     306,  -102,   147,  -102,    96,    88,    89,    90,    91,   310,
      94,    95,   178,   173,   252,   253,   154,   278,   157,   268,
       7,   235,   118,   120,   107,   124,   107,   260,   106,   129,
     107,   260,  -155,    69,    98,   107,   256,   108,   110,  -171,
     105,   190,   235,    92,     7,   247,   170,   121,   251,   111,
     112,   113,   114,   115,   116,   123,   166,   125,   136,   127,
     169,    81,   287,    82,    99,   217,   103,   218,   235,   138,
     139,    83,   107,  -161,    84,   107,  -161,   151,  -161,   255,
     259,   144,   101,   159,     7,     7,  -161,    85,   162,   117,
     119,  -161,    86,    87,     4,   147,   128,  -161,     5,   135,
     144,   160,  -155,    69,   263,   142,     8,   139,   172,     7,
     150,   235,   152,   153,   187,   156,   280,   158,   175,   281,
     144,     7,   179,   165,     7,   184,   191,   168,   204,   277,
     235,   207,   174,   193,   194,   176,   200,   235,   197,   214,
       7,   206,   144,   170,    69,   235,   235,   211,   246,   216,
     265,   245,   279,     4,   234,   195,   248,     5,   196,   185,
     283,   288,   295,   300,   214,     8,   299,   307,   258,   303,
     200,   304,    78,   261,   189,   234,   200,   308,   262,   220,
     266,    -3,   177,   309,   291,     4,   250,   257,    38,     5,
     211,   209,     1,   181,   271,     2,    39,     8,   294,    40,
     276,   234,     3,   167,     4,   284,   205,   264,     5,   254,
       0,     0,    41,    42,     6,     7,     8,    43,    44,     0,
       0,     0,     0,     0,     0,     0,     1,   200,     0,     2,
       0,     0,   285,     0,     0,     0,     3,     0,     4,   290,
       0,   293,     5,     0,   234,     0,   297,     0,     6,     7,
       8,     0,     0,     0,     0,     0,     0,     0,   282,     0,
       0,     0,     0,   234,     0,     0,     0,     0,     0,     0,
     234,     0,   293,     0,   312,     0,     0,     0,   234,   234,
       0,     0,     0,     0,   161,     0,     0,    45,     0,    46,
       0,     0,     0,    47,     0,    48,    49,    50,    51,     0,
      52,     0,     0,     0,     4,     0,    64,     0,     5,   313,
     314,    53,     0,    54,    55,     0,     8,    56,    57,    58,
      45,     0,    46,     0,     0,     0,   221,   222,   223,   224,
      50,    51,   225,    52,   226,   227,     0,     4,   228,   229,
       0,     5,   267,     0,   230,     0,    54,    55,   231,     8,
     232,    57,    58,   233,    45,     0,    46,     0,     0,     0,
     221,   222,   223,   224,    50,    51,   225,    52,   226,   227,
       0,     4,   228,   229,     0,     5,   286,     0,   230,     0,
      54,    55,   231,     8,   232,    57,    58,   233,    45,     0,
      46,     0,     0,     0,   221,   222,   223,   224,    50,    51,
     225,    52,   226,   227,     0,     4,   228,   229,     0,     5,
       0,     0,   230,     0,    54,    55,   231,     8,   232,    57,
      58,   233,    45,     0,    46,     0,     0,     0,   221,   222,
     223,   224,    50,    51,   225,    52,   226,   305,     0,     4,
     228,   229,     0,     5,     0,     0,   230,     0,    54,    55,
     231,     8,   232,    57,    58,    45,     0,    46,    63,     0,
       0,    47,     0,    48,    49,    50,    51,     0,    52,     0,
       0,     0,     4,     0,    64,     0,     5,     0,    65,    53,
       0,    54,    55,     0,     8,    56,    57,    58,    45,     0,
      46,    63,     0,     0,    47,     0,    48,    49,    50,    51,
       0,    52,     0,     0,     0,     4,     0,    64,     0,     5,
       0,   100,    53,     0,    54,    55,     0,     8,    56,    57,
      58,    45,     0,    46,    63,     0,     0,    47,     0,    48,
      49,    50,    51,     0,    52,     0,     0,     0,     4,     0,
      64,     0,     5,     0,   219,    53,     0,    54,    55,     0,
       8,    56,    57,    58,    45,    73,    46,     0,     0,     0,
      47,     0,    48,    49,    50,    51,     0,    52,     0,     0,
       0,     4,     0,    97,     0,     5,     0,     0,    53,     0,
      54,    55,     0,     8,    56,    57,    58,    45,     0,    46,
       0,     0,     0,    47,     0,    48,    49,    50,    51,     0,
      52,   130,     0,     0,     4,     0,    64,     0,     5,     0,
       0,    53,     0,    54,    55,     0,     8,    56,    57,    58,
      45,     0,    46,    63,     0,     0,    47,     0,    48,    49,
      50,    51,     0,    52,     0,     0,     0,     4,     0,    64,
       0,     5,     0,     0,    53,     0,    54,    55,     0,     8,
      56,    57,    58,    45,     0,    46,     0,     0,     0,    47,
       0,    48,    49,    50,    51,     0,    52,     0,     0,     0,
       4,     0,    64,     0,     5,     0,     0,    53,   180,    54,
      55,     0,     8,    56,    57,    58,    45,     0,    46,     0,
       0,     0,    47,     0,    48,    49,    50,    51,     0,    52,
       0,     0,     0,     4,     0,    64,     0,     5,     0,   270,
      53,     0,    54,    55,     0,     8,    56,    57,    58,    45,
       0,    46,     0,     0,     0,    47,     0,    48,    49,    50,
      51,     0,    52,     0,     0,     0,     4,     0,    64,     0,
       5,     0,   289,    53,     0,    54,    55,     0,     8,    56,
      57,    58,    45,     0,    46,     0,     0,     0,    47,     0,
      48,    49,    50,    51,     0,    52,     0,     0,     0,     4,
       0,    64,     0,     5,     0,   292,    53,     0,    54,    55,
       0,     8,    56,    57,    58,    45,     0,    46,     0,     0,
       0,    47,     0,    48,    49,    50,    51,     0,    52,     0,
       0,     0,     4,     0,    64,     0,     5,     0,   311,    53,
       0,    54,    55,     0,     8,    56,    57,    58,    45,     0,
      46,     0,     0,     0,    47,     0,    48,    49,    50,    51,
       0,    52,     0,     0,     0,     4,     0,    64,     0,     5,
       0,     0,    53,     0,    54,    55,     0,     8,    56,    57,
      58,    45,     0,    46,     0,     0,     0,    47,     0,    48,
      49,    50,    51,     0,    52,     0,     0,     0,     4,     0,
       0,     0,     5,     0,     0,    53,     0,    54,    55,     0,
       8,    56,    57,    58,    45,     0,    46,     0,     0,     0,
       0,     0,   223,   224,    50,    51,     0,    52,     0,     0,
       0,     4,     0,   229,     0,     5,     0,     0,   230,     0,
      54,    55,     0,     8,     0,    57,    58
};

static const yytype_int16 yycheck[] =
{
       3,    66,   179,     2,   145,     0,    42,     0,     5,   105,
      97,    75,    15,   203,   165,   199,    11,   168,    11,     7,
      99,     7,     0,   288,    31,    22,   167,    94,     7,    93,
     295,    10,    39,    21,    25,    38,    39,    40,    41,   304,
      43,    44,   138,   130,   195,   196,   113,    31,   115,   226,
      34,   179,    88,    89,   118,    91,   120,   247,    21,    95,
     124,   251,     7,    66,    63,   129,   250,    22,     7,    29,
      73,   150,   200,    42,    34,   191,    21,    17,   194,    82,
      83,    84,    85,    86,    87,    90,   122,    21,    21,    94,
     126,     6,   269,     8,    63,   174,    22,   176,   226,   102,
     103,    16,   166,    12,    19,   169,    15,   110,    17,    29,
      29,   106,   177,    21,    34,    34,    25,    32,   121,    88,
      89,    30,    37,    38,    23,    39,    95,    36,    27,    98,
     125,    21,     7,   136,    29,   104,    35,   140,    10,    34,
     109,   269,   111,   112,   147,   114,    29,   116,     4,    29,
     145,    34,     5,   122,    34,     5,    22,   126,   161,   246,
     288,   164,   131,    21,    21,   134,   159,   295,    10,   172,
      34,     3,   167,    21,   177,   303,   304,   170,     5,    28,
      26,   184,    25,    23,   179,   154,    30,    27,   157,    29,
       5,     5,    10,     5,   197,    35,   283,    26,   201,     5,
     193,     5,    11,   206,   148,   200,   199,   299,   211,   178,
     220,     0,   136,   300,   272,    23,   193,   200,     8,    27,
     213,    29,    11,   140,   227,    14,    16,    35,   274,    19,
     233,   226,    21,   125,    23,   262,   161,   213,    27,   197,
      -1,    -1,    32,    33,    33,    34,    35,    37,    38,    -1,
      -1,    -1,    -1,    -1,    -1,    -1,    11,   250,    -1,    14,
      -1,    -1,   265,    -1,    -1,    -1,    21,    -1,    23,   272,
      -1,   274,    27,    -1,   269,    -1,   279,    -1,    33,    34,
      35,    -1,    -1,    -1,    -1,    -1,    -1,    -1,   257,    -1,
      -1,    -1,    -1,   288,    -1,    -1,    -1,    -1,    -1,    -1,
     295,    -1,   305,    -1,   307,    -1,    -1,    -1,   303,   304,
      -1,    -1,    -1,    -1,     3,    -1,    -1,     6,    -1,     8,
      -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,
      19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,   308,
     309,    30,    -1,    32,    33,    -1,    35,    36,    37,    38,
       6,    -1,     8,    -1,    -1,    -1,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    -1,    23,    24,    25,
      -1,    27,    28,    -1,    30,    -1,    32,    33,    34,    35,
      36,    37,    38,    39,     6,    -1,     8,    -1,    -1,    -1,
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
      -1,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,    29,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,
      27,    -1,    29,    30,    -1,    32,    33,    -1,    35,    36,
      37,    38,     6,    -1,     8,    -1,    -1,    -1,    12,    -1,
      14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,
      -1,    25,    -1,    27,    -1,    29,    30,    -1,    32,    33,
      -1,    35,    36,    37,    38,     6,    -1,     8,    -1,    -1,
      -1,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    -1,    25,    -1,    27,    -1,    29,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38,     6,    -1,
       8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,    17,
      -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,    27,
      -1,    -1,    30,    -1,    32,    33,    -1,    35,    36,    37,
      38,     6,    -1,     8,    -1,    -1,    -1,    12,    -1,    14,
      15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,    -1,
      -1,    -1,    27,    -1,    -1,    30,    -1,    32,    33,    -1,
      35,    36,    37,    38,     6,    -1,     8,    -1,    -1,    -1,
      -1,    -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,
      -1,    23,    -1,    25,    -1,    27,    -1,    -1,    30,    -1,
      32,    33,    -1,    35,    -1,    37,    38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    11,    14,    21,    23,    27,    33,    34,    35,    41,
      42,    43,    44,    45,    46,    47,    87,    89,    90,    93,
      94,    95,    96,    97,    98,    99,   100,   101,   102,   103,
     104,   105,   106,   117,   119,   120,   121,   122,     8,    16,
      19,    32,    33,    37,    38,     6,     8,    12,    14,    15,
      16,    17,    19,    30,    32,    33,    36,    37,    38,    47,
      61,    62,    88,     9,    25,    29,    57,    58,    59,    60,
      62,    85,    86,     7,    82,    83,    84,     0,    44,    48,
      60,     6,     8,    16,    19,    32,    37,    38,    60,    60,
      60,    60,    82,    83,    60,    60,    25,    25,    62,    82,
      29,    58,     5,    22,    66,    60,    21,    84,    22,    49,
       7,    60,    60,    60,    60,    60,    60,    82,    83,    82,
      83,    17,   107,   108,    83,    21,   107,   108,    82,    83,
      20,    52,    53,    60,    52,    82,    21,    55,    60,    60,
      67,    68,    82,    66,    47,    91,    92,    39,    50,    51,
      82,    60,    82,    82,   107,   108,    82,   107,    82,    21,
      21,     3,    60,   109,   110,    82,    83,    91,    82,    83,
      21,   115,    10,    52,    82,     4,    82,    57,    66,     5,
      31,    68,    55,    56,     5,    29,    92,    60,    31,    51,
      55,    22,   113,    21,    21,    82,    82,    10,    64,    65,
     104,   104,   111,   112,    60,   109,     3,    60,   115,    29,
     115,   104,   114,   116,    60,   118,    28,    55,    55,    29,
      82,    12,    13,    14,    15,    18,    20,    21,    24,    25,
      30,    34,    36,    39,    47,    61,    63,    69,    70,    71,
      72,    73,    75,    78,    81,    60,     5,   112,    30,   123,
      65,   112,   115,   115,   118,    29,    64,    63,    60,    29,
     111,    60,    60,    29,   114,    26,    56,    28,    70,    74,
      29,    60,    76,    77,    79,    80,    60,    52,    31,    25,
      29,    29,    82,     5,   113,    60,    28,    70,     5,    29,
      60,    77,    29,    60,    80,    10,    54,    60,   124,    52,
       5,    69,    70,     5,     5,    21,    69,    26,    54,    52,
      69,    29,    60,    82,    82
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    44,    44,    44,    45,
      45,    46,    46,    46,    47,    47,    47,    48,    48,    49,
      49,    50,    50,    51,    52,    52,    53,    53,    54,    54,
      55,    56,    56,    57,    57,    58,    58,    58,    59,    59,
      60,    60,    61,    61,    61,    61,    61,    61,    61,    61,
      61,    62,    62,    62,    62,    62,    62,    62,    63,    63,
      63,    63,    63,    63,    64,    65,    65,    66,    66,    67,
      67,    68,    69,    69,    69,    69,    69,    69,    69,    69,
      69,    70,    70,    70,    71,    72,    73,    73,    74,    74,
      75,    75,    76,    76,    77,    78,    78,    79,    79,    80,
      81,    82,    82,    83,    83,    84,    85,    86,    86,    87,
      88,    88,    89,    89,    89,    90,    91,    91,    92,    93,
      93,    93,    93,    93,    93,    94,    94,    95,    95,    96,
      96,    96,    96,    96,    96,    97,    98,    98,    98,    98,
      99,    99,    99,   100,   100,   101,   101,   102,   102,   103,
     104,   104,   105,   106,   107,   107,   108,   108,   108,   109,
     109,   110,   110,   111,   112,   112,   113,   113,   114,   115,
     115,   116,   116,   116,   117,   118,   118,   119,   120,   121,
     122,   123,   123,   124,   124
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     1,     2,     1,     1,     1,     1,
       1,     5,     3,     2,     1,     1,     1,     0,     1,     0,
       3,     1,     2,     5,     1,     2,     1,     3,     0,     2,
       3,     0,     1,     1,     2,     1,     1,     1,     4,     6,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     3,     1,     2,     0,     3,     1,
       2,     3,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     2,     2,     3,     1,     2,
       2,     3,     1,     2,     3,     2,     3,     1,     2,     3,
       1,     0,     1,     1,     2,     3,     3,     5,     3,     6,
       0,     1,     1,     1,     1,     5,     1,     2,     3,     1,
       1,     1,     1,     1,     1,     1,     1,     6,     3,     1,
       1,     1,     1,     1,     1,     4,     5,     6,     5,     4,
       6,     5,     4,     6,     4,     7,     4,     7,     4,     1,
       0,     1,     4,     6,     0,     1,     3,     2,     2,     1,
       3,     1,     2,     6,     1,     2,     0,     3,     6,     0,
       3,     0,     1,     2,     6,     1,     3,     6,     7,     7,
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
        yyerror (YY_("syntax error: cannot back up")); \
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
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
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
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
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
                 int yyrule)
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
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
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






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
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
yyparse (void)
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
      yychar = yylex (&yylval);
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
  case 3: /* document: definitions_list  */
#line 56 "ext/graphql_ext/parser.y"
                             { result = make_node(:Document, definitions: val[0])}
#line 1684 "ext/graphql_ext/parser.c"
    break;

  case 4: /* definitions_list: definition  */
#line 59 "ext/graphql_ext/parser.y"
                                    { result = [val[0]]}
#line 1690 "ext/graphql_ext/parser.c"
    break;

  case 5: /* definitions_list: definitions_list definition  */
#line 60 "ext/graphql_ext/parser.y"
                                    { val[0] << val[1] }
#line 1696 "ext/graphql_ext/parser.c"
    break;

  case 11: /* operation_definition: operation_type operation_name_opt variable_definitions_opt directives_list_opt selection_set  */
#line 72 "ext/graphql_ext/parser.y"
                                                                                                   {
        result = make_node(
          :OperationDefinition, {
            operation_type: val[0],
            name:           val[1],
            variables:      val[2],
            directives:     val[3],
            selections:     val[4],
            position_source: val[0],
          }
        )
      }
#line 1713 "ext/graphql_ext/parser.c"
    break;

  case 12: /* operation_definition: LCURLY selection_list RCURLY  */
#line 84 "ext/graphql_ext/parser.y"
                                   {
        result = make_node(
          :OperationDefinition, {
            operation_type: "query",
            selections: val[1],
            position_source: val[0],
          }
        )
      }
#line 1727 "ext/graphql_ext/parser.c"
    break;

  case 13: /* operation_definition: LCURLY RCURLY  */
#line 93 "ext/graphql_ext/parser.y"
                    {
        result = make_node(
          :OperationDefinition, {
            operation_type: "query",
            selections: [],
            position_source: val[0],
          }
        )
      }
#line 1741 "ext/graphql_ext/parser.c"
    break;

  case 17: /* operation_name_opt: %empty  */
#line 109 "ext/graphql_ext/parser.y"
                 { result = nil }
#line 1747 "ext/graphql_ext/parser.c"
    break;

  case 19: /* variable_definitions_opt: %empty  */
#line 113 "ext/graphql_ext/parser.y"
                                              { result = EMPTY_ARRAY }
#line 1753 "ext/graphql_ext/parser.c"
    break;

  case 20: /* variable_definitions_opt: LPAREN variable_definitions_list RPAREN  */
#line 114 "ext/graphql_ext/parser.y"
                                              { result = val[1] }
#line 1759 "ext/graphql_ext/parser.c"
    break;

  case 21: /* variable_definitions_list: variable_definition  */
#line 117 "ext/graphql_ext/parser.y"
                                                    { result = [val[0]] }
#line 1765 "ext/graphql_ext/parser.c"
    break;

  case 22: /* variable_definitions_list: variable_definitions_list variable_definition  */
#line 118 "ext/graphql_ext/parser.y"
                                                    { val[0] << val[1] }
#line 1771 "ext/graphql_ext/parser.c"
    break;

  case 23: /* variable_definition: VAR_SIGN name COLON type default_value_opt  */
#line 121 "ext/graphql_ext/parser.y"
                                                 {
        result = make_node(:VariableDefinition, {
          name: val[1],
          type: val[3],
          default_value: val[4],
          position_source: val[0],
        })
      }
#line 1784 "ext/graphql_ext/parser.c"
    break;

  case 24: /* type: nullable_type  */
#line 131 "ext/graphql_ext/parser.y"
                              { result = val[0] }
#line 1790 "ext/graphql_ext/parser.c"
    break;

  case 25: /* type: nullable_type BANG  */
#line 132 "ext/graphql_ext/parser.y"
                              { result = make_node(:NonNullType, of_type: val[0]) }
#line 1796 "ext/graphql_ext/parser.c"
    break;

  case 26: /* nullable_type: name  */
#line 135 "ext/graphql_ext/parser.y"
                             { result = make_node(:TypeName, name: val[0])}
#line 1802 "ext/graphql_ext/parser.c"
    break;

  case 27: /* nullable_type: LBRACKET type RBRACKET  */
#line 136 "ext/graphql_ext/parser.y"
                             { result = make_node(:ListType, of_type: val[1]) }
#line 1808 "ext/graphql_ext/parser.c"
    break;

  case 28: /* default_value_opt: %empty  */
#line 139 "ext/graphql_ext/parser.y"
                            { result = nil }
#line 1814 "ext/graphql_ext/parser.c"
    break;

  case 29: /* default_value_opt: EQUALS literal_value  */
#line 140 "ext/graphql_ext/parser.y"
                            { result = val[1] }
#line 1820 "ext/graphql_ext/parser.c"
    break;

  case 30: /* selection_set: LCURLY selection_list RCURLY  */
#line 143 "ext/graphql_ext/parser.y"
                                   { result = val[1] }
#line 1826 "ext/graphql_ext/parser.c"
    break;

  case 31: /* selection_set_opt: %empty  */
#line 146 "ext/graphql_ext/parser.y"
                    { result = EMPTY_ARRAY }
#line 1832 "ext/graphql_ext/parser.c"
    break;

  case 32: /* selection_set_opt: selection_set  */
#line 147 "ext/graphql_ext/parser.y"
                    { result = val[0] }
#line 1838 "ext/graphql_ext/parser.c"
    break;

  case 33: /* selection_list: selection  */
#line 150 "ext/graphql_ext/parser.y"
                                { result = [result] }
#line 1844 "ext/graphql_ext/parser.c"
    break;

  case 34: /* selection_list: selection_list selection  */
#line 151 "ext/graphql_ext/parser.y"
                                { val[0] << val[1] }
#line 1850 "ext/graphql_ext/parser.c"
    break;

  case 38: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 159 "ext/graphql_ext/parser.y"
                                                               {
            result = make_node(
              :Field, {
                name:         val[0],
                arguments:    val[1],
                directives:   val[2],
                selections:   val[3],
                position_source: val[0],
              }
            )
          }
#line 1866 "ext/graphql_ext/parser.c"
    break;

  case 39: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 170 "ext/graphql_ext/parser.y"
                                                                          {
            result = make_node(
              :Field, {
                alias:        val[0],
                name:         val[2],
                arguments:    val[3],
                directives:   val[4],
                selections:   val[5],
                position_source: val[0],
              }
            )
          }
#line 1883 "ext/graphql_ext/parser.c"
    break;

  case 64: /* enum_value_definition: description_opt enum_name directives_list_opt  */
#line 216 "ext/graphql_ext/parser.y"
                                                  { result = make_node(:EnumValueDefinition, name: val[1], directives: val[2], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1]) }
#line 1889 "ext/graphql_ext/parser.c"
    break;

  case 65: /* enum_value_definitions: enum_value_definition  */
#line 219 "ext/graphql_ext/parser.y"
                                                   { result = [val[0]] }
#line 1895 "ext/graphql_ext/parser.c"
    break;

  case 66: /* enum_value_definitions: enum_value_definitions enum_value_definition  */
#line 220 "ext/graphql_ext/parser.y"
                                                   { result = val[0] << val[1] }
#line 1901 "ext/graphql_ext/parser.c"
    break;

  case 67: /* arguments_opt: %empty  */
#line 223 "ext/graphql_ext/parser.y"
                                    { result = EMPTY_ARRAY }
#line 1907 "ext/graphql_ext/parser.c"
    break;

  case 68: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 224 "ext/graphql_ext/parser.y"
                                    { result = val[1] }
#line 1913 "ext/graphql_ext/parser.c"
    break;

  case 69: /* arguments_list: argument  */
#line 227 "ext/graphql_ext/parser.y"
                              { result = [val[0]] }
#line 1919 "ext/graphql_ext/parser.c"
    break;

  case 70: /* arguments_list: arguments_list argument  */
#line 228 "ext/graphql_ext/parser.y"
                              { val[0] << val[1] }
#line 1925 "ext/graphql_ext/parser.c"
    break;

  case 71: /* argument: name COLON input_value  */
#line 231 "ext/graphql_ext/parser.y"
                             { result = make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}
#line 1931 "ext/graphql_ext/parser.c"
    break;

  case 72: /* literal_value: FLOAT  */
#line 234 "ext/graphql_ext/parser.y"
                  { result = val[0][3].to_f }
#line 1937 "ext/graphql_ext/parser.c"
    break;

  case 73: /* literal_value: INT  */
#line 235 "ext/graphql_ext/parser.y"
                  { result = val[0][3].to_i }
#line 1943 "ext/graphql_ext/parser.c"
    break;

  case 74: /* literal_value: STRING  */
#line 236 "ext/graphql_ext/parser.y"
                  { result = val[0][3] }
#line 1949 "ext/graphql_ext/parser.c"
    break;

  case 75: /* literal_value: TRUE_LITERAL  */
#line 237 "ext/graphql_ext/parser.y"
                          { result = true }
#line 1955 "ext/graphql_ext/parser.c"
    break;

  case 76: /* literal_value: FALSE_LITERAL  */
#line 238 "ext/graphql_ext/parser.y"
                          { result = false }
#line 1961 "ext/graphql_ext/parser.c"
    break;

  case 84: /* null_value: NULL_LITERAL  */
#line 249 "ext/graphql_ext/parser.y"
                           { result = make_node(:NullValue, name: val[0], position_source: val[0]) }
#line 1967 "ext/graphql_ext/parser.c"
    break;

  case 85: /* variable: VAR_SIGN name  */
#line 250 "ext/graphql_ext/parser.y"
                          { result = make_node(:VariableIdentifier, name: val[1], position_source: val[0]) }
#line 1973 "ext/graphql_ext/parser.c"
    break;

  case 86: /* list_value: LBRACKET RBRACKET  */
#line 253 "ext/graphql_ext/parser.y"
                                        { result = EMPTY_ARRAY }
#line 1979 "ext/graphql_ext/parser.c"
    break;

  case 87: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 254 "ext/graphql_ext/parser.y"
                                        { result = val[1] }
#line 1985 "ext/graphql_ext/parser.c"
    break;

  case 88: /* list_value_list: input_value  */
#line 257 "ext/graphql_ext/parser.y"
                                  { result = [val[0]] }
#line 1991 "ext/graphql_ext/parser.c"
    break;

  case 89: /* list_value_list: list_value_list input_value  */
#line 258 "ext/graphql_ext/parser.y"
                                  { val[0] << val[1] }
#line 1997 "ext/graphql_ext/parser.c"
    break;

  case 90: /* object_value: LCURLY RCURLY  */
#line 261 "ext/graphql_ext/parser.y"
                                      { result = make_node(:InputObject, arguments: [], position_source: val[0])}
#line 2003 "ext/graphql_ext/parser.c"
    break;

  case 91: /* object_value: LCURLY object_value_list RCURLY  */
#line 262 "ext/graphql_ext/parser.y"
                                      { result = make_node(:InputObject, arguments: val[1], position_source: val[0])}
#line 2009 "ext/graphql_ext/parser.c"
    break;

  case 92: /* object_value_list: object_value_field  */
#line 265 "ext/graphql_ext/parser.y"
                                            { result = [val[0]] }
#line 2015 "ext/graphql_ext/parser.c"
    break;

  case 93: /* object_value_list: object_value_list object_value_field  */
#line 266 "ext/graphql_ext/parser.y"
                                            { val[0] << val[1] }
#line 2021 "ext/graphql_ext/parser.c"
    break;

  case 94: /* object_value_field: name COLON input_value  */
#line 269 "ext/graphql_ext/parser.y"
                             { result = make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}
#line 2027 "ext/graphql_ext/parser.c"
    break;

  case 95: /* object_literal_value: LCURLY RCURLY  */
#line 273 "ext/graphql_ext/parser.y"
                                              { result = make_node(:InputObject, arguments: [], position_source: val[0])}
#line 2033 "ext/graphql_ext/parser.c"
    break;

  case 96: /* object_literal_value: LCURLY object_literal_value_list RCURLY  */
#line 274 "ext/graphql_ext/parser.y"
                                              { result = make_node(:InputObject, arguments: val[1], position_source: val[0])}
#line 2039 "ext/graphql_ext/parser.c"
    break;

  case 97: /* object_literal_value_list: object_literal_value_field  */
#line 277 "ext/graphql_ext/parser.y"
                                                            { result = [val[0]] }
#line 2045 "ext/graphql_ext/parser.c"
    break;

  case 98: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 278 "ext/graphql_ext/parser.y"
                                                            { val[0] << val[1] }
#line 2051 "ext/graphql_ext/parser.c"
    break;

  case 99: /* object_literal_value_field: name COLON literal_value  */
#line 281 "ext/graphql_ext/parser.y"
                               { result = make_node(:Argument, name: val[0], value: val[2], position_source: val[0])}
#line 2057 "ext/graphql_ext/parser.c"
    break;

  case 100: /* enum_value: enum_name  */
#line 283 "ext/graphql_ext/parser.y"
                        { result = make_node(:Enum, name: val[0], position_source: val[0]) }
#line 2063 "ext/graphql_ext/parser.c"
    break;

  case 101: /* directives_list_opt: %empty  */
#line 286 "ext/graphql_ext/parser.y"
                      { result = EMPTY_ARRAY }
#line 2069 "ext/graphql_ext/parser.c"
    break;

  case 103: /* directives_list: directive  */
#line 290 "ext/graphql_ext/parser.y"
                                { result = [val[0]] }
#line 2075 "ext/graphql_ext/parser.c"
    break;

  case 104: /* directives_list: directives_list directive  */
#line 291 "ext/graphql_ext/parser.y"
                                { val[0] << val[1] }
#line 2081 "ext/graphql_ext/parser.c"
    break;

  case 105: /* directive: DIR_SIGN name arguments_opt  */
#line 293 "ext/graphql_ext/parser.y"
                                         { result = make_node(:Directive, name: val[1], arguments: val[2], position_source: val[0]) }
#line 2087 "ext/graphql_ext/parser.c"
    break;

  case 106: /* fragment_spread: ELLIPSIS name_without_on directives_list_opt  */
#line 296 "ext/graphql_ext/parser.y"
                                                   { result = make_node(:FragmentSpread, name: val[1], directives: val[2], position_source: val[0]) }
#line 2093 "ext/graphql_ext/parser.c"
    break;

  case 107: /* inline_fragment: ELLIPSIS ON type directives_list_opt selection_set  */
#line 299 "ext/graphql_ext/parser.y"
                                                         {
        result = make_node(:InlineFragment, {
          type: val[2],
          directives: val[3],
          selections: val[4],
          position_source: val[0]
        })
      }
#line 2106 "ext/graphql_ext/parser.c"
    break;

  case 108: /* inline_fragment: ELLIPSIS directives_list_opt selection_set  */
#line 307 "ext/graphql_ext/parser.y"
                                                 {
        result = make_node(:InlineFragment, {
          type: nil,
          directives: val[1],
          selections: val[2],
          position_source: val[0]
        })
      }
#line 2119 "ext/graphql_ext/parser.c"
    break;

  case 109: /* fragment_definition: FRAGMENT fragment_name_opt ON type directives_list_opt selection_set  */
#line 317 "ext/graphql_ext/parser.y"
                                                                         {
      result = make_node(:FragmentDefinition, {
          name:       val[1],
          type:       val[3],
          directives: val[4],
          selections: val[5],
          position_source: val[0],
        }
      )
    }
#line 2134 "ext/graphql_ext/parser.c"
    break;

  case 110: /* fragment_name_opt: %empty  */
#line 329 "ext/graphql_ext/parser.y"
                 { result = nil }
#line 2140 "ext/graphql_ext/parser.c"
    break;

  case 115: /* schema_definition: SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 338 "ext/graphql_ext/parser.y"
                                                                              { result = make_node(:SchemaDefinition, position_source: val[0], definition_line: val[0][1], directives: val[1], **val[3]) }
#line 2146 "ext/graphql_ext/parser.c"
    break;

  case 117: /* operation_type_definition_list: operation_type_definition_list operation_type_definition  */
#line 342 "ext/graphql_ext/parser.y"
                                                               { result = val[0].merge(val[1]) }
#line 2152 "ext/graphql_ext/parser.c"
    break;

  case 118: /* operation_type_definition: operation_type COLON name  */
#line 345 "ext/graphql_ext/parser.y"
                                { result = { val[0][3].to_sym => val[2] } }
#line 2158 "ext/graphql_ext/parser.c"
    break;

  case 127: /* schema_extension: EXTEND SCHEMA directives_list_opt LCURLY operation_type_definition_list RCURLY  */
#line 360 "ext/graphql_ext/parser.y"
                                                                                     { result = make_node(:SchemaExtension, position_source: val[0], directives: val[2], **val[4]) }
#line 2164 "ext/graphql_ext/parser.c"
    break;

  case 128: /* schema_extension: EXTEND SCHEMA directives_list  */
#line 361 "ext/graphql_ext/parser.y"
                                    { result = make_node(:SchemaExtension, position_source: val[0], directives: val[2]) }
#line 2170 "ext/graphql_ext/parser.c"
    break;

  case 135: /* scalar_type_extension: EXTEND SCALAR name directives_list  */
#line 371 "ext/graphql_ext/parser.y"
                                                            { result = make_node(:ScalarTypeExtension, name: val[2], directives: val[3], position_source: val[0]) }
#line 2176 "ext/graphql_ext/parser.c"
    break;

  case 136: /* object_type_extension: EXTEND TYPE_LITERAL name implements field_definition_list_opt  */
#line 375 "ext/graphql_ext/parser.y"
                                                                    { result = make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: [], fields: val[4], position_source: val[0]) }
#line 2182 "ext/graphql_ext/parser.c"
    break;

  case 137: /* object_type_extension: EXTEND TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 376 "ext/graphql_ext/parser.y"
                                                                                            { result = make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: val[4], fields: val[5], position_source: val[0]) }
#line 2188 "ext/graphql_ext/parser.c"
    break;

  case 138: /* object_type_extension: EXTEND TYPE_LITERAL name implements_opt directives_list  */
#line 377 "ext/graphql_ext/parser.y"
                                                              { result = make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: val[4], fields: [], position_source: val[0]) }
#line 2194 "ext/graphql_ext/parser.c"
    break;

  case 139: /* object_type_extension: EXTEND TYPE_LITERAL name implements  */
#line 378 "ext/graphql_ext/parser.y"
                                          { result = make_node(:ObjectTypeExtension, name: val[2], interfaces: val[3], directives: [], fields: [], position_source: val[0]) }
#line 2200 "ext/graphql_ext/parser.c"
    break;

  case 140: /* interface_type_extension: EXTEND INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 381 "ext/graphql_ext/parser.y"
                                                                                         { result = make_node(:InterfaceTypeExtension, name: val[2], interfaces: val[3], directives: val[4], fields: val[5], position_source: val[0]) }
#line 2206 "ext/graphql_ext/parser.c"
    break;

  case 141: /* interface_type_extension: EXTEND INTERFACE name implements_opt directives_list  */
#line 382 "ext/graphql_ext/parser.y"
                                                           { result = make_node(:InterfaceTypeExtension, name: val[2], interfaces: val[3], directives: val[4], fields: [], position_source: val[0]) }
#line 2212 "ext/graphql_ext/parser.c"
    break;

  case 142: /* interface_type_extension: EXTEND INTERFACE name implements  */
#line 383 "ext/graphql_ext/parser.y"
                                       { result = make_node(:InterfaceTypeExtension, name: val[2], interfaces: val[3], directives: [], fields: [], position_source: val[0]) }
#line 2218 "ext/graphql_ext/parser.c"
    break;

  case 143: /* union_type_extension: EXTEND UNION name directives_list_opt EQUALS union_members  */
#line 386 "ext/graphql_ext/parser.y"
                                                                 { result = make_node(:UnionTypeExtension, name: val[2], directives: val[3], types: val[5], position_source: val[0]) }
#line 2224 "ext/graphql_ext/parser.c"
    break;

  case 144: /* union_type_extension: EXTEND UNION name directives_list  */
#line 387 "ext/graphql_ext/parser.y"
                                        { result = make_node(:UnionTypeExtension, name: val[2], directives: val[3], types: [], position_source: val[0]) }
#line 2230 "ext/graphql_ext/parser.c"
    break;

  case 145: /* enum_type_extension: EXTEND ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 390 "ext/graphql_ext/parser.y"
                                                                                { result = make_node(:EnumTypeExtension, name: val[2], directives: val[3], values: val[5], position_source: val[0]) }
#line 2236 "ext/graphql_ext/parser.c"
    break;

  case 146: /* enum_type_extension: EXTEND ENUM name directives_list  */
#line 391 "ext/graphql_ext/parser.y"
                                       { result = make_node(:EnumTypeExtension, name: val[2], directives: val[3], values: [], position_source: val[0]) }
#line 2242 "ext/graphql_ext/parser.c"
    break;

  case 147: /* input_object_type_extension: EXTEND INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 394 "ext/graphql_ext/parser.y"
                                                                                      { result = make_node(:InputObjectTypeExtension, name: val[2], directives: val[3], fields: val[5], position_source: val[0]) }
#line 2248 "ext/graphql_ext/parser.c"
    break;

  case 148: /* input_object_type_extension: EXTEND INPUT name directives_list  */
#line 395 "ext/graphql_ext/parser.y"
                                        { result = make_node(:InputObjectTypeExtension, name: val[2], directives: val[3], fields: [], position_source: val[0]) }
#line 2254 "ext/graphql_ext/parser.c"
    break;

  case 152: /* scalar_type_definition: description_opt SCALAR name directives_list_opt  */
#line 404 "ext/graphql_ext/parser.y"
                                                      {
        result = make_node(:ScalarTypeDefinition, name: val[2], directives: val[3], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2262 "ext/graphql_ext/parser.c"
    break;

  case 153: /* object_type_definition: description_opt TYPE_LITERAL name implements_opt directives_list_opt field_definition_list_opt  */
#line 409 "ext/graphql_ext/parser.y"
                                                                                                     {
        result = make_node(:ObjectTypeDefinition, name: val[2], interfaces: val[3], directives: val[4], fields: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2270 "ext/graphql_ext/parser.c"
    break;

  case 154: /* implements_opt: %empty  */
#line 414 "ext/graphql_ext/parser.y"
                 { result = EMPTY_ARRAY }
#line 2276 "ext/graphql_ext/parser.c"
    break;

  case 156: /* implements: IMPLEMENTS AMP interfaces_list  */
#line 418 "ext/graphql_ext/parser.y"
                                     { result = val[2] }
#line 2282 "ext/graphql_ext/parser.c"
    break;

  case 157: /* implements: IMPLEMENTS interfaces_list  */
#line 419 "ext/graphql_ext/parser.y"
                                 { result = val[1] }
#line 2288 "ext/graphql_ext/parser.c"
    break;

  case 158: /* implements: IMPLEMENTS legacy_interfaces_list  */
#line 420 "ext/graphql_ext/parser.y"
                                        { result = val[1] }
#line 2294 "ext/graphql_ext/parser.c"
    break;

  case 159: /* interfaces_list: name  */
#line 423 "ext/graphql_ext/parser.y"
                               { result = [make_node(:TypeName, name: val[0], position_source: val[0])] }
#line 2300 "ext/graphql_ext/parser.c"
    break;

  case 160: /* interfaces_list: interfaces_list AMP name  */
#line 424 "ext/graphql_ext/parser.y"
                               { val[0] << make_node(:TypeName, name: val[2], position_source: val[2]) }
#line 2306 "ext/graphql_ext/parser.c"
    break;

  case 161: /* legacy_interfaces_list: name  */
#line 427 "ext/graphql_ext/parser.y"
                                  { result = [make_node(:TypeName, name: val[0], position_source: val[0])] }
#line 2312 "ext/graphql_ext/parser.c"
    break;

  case 162: /* legacy_interfaces_list: legacy_interfaces_list name  */
#line 428 "ext/graphql_ext/parser.y"
                                  { val[0] << make_node(:TypeName, name: val[1], position_source: val[1]) }
#line 2318 "ext/graphql_ext/parser.c"
    break;

  case 163: /* input_value_definition: description_opt name COLON type default_value_opt directives_list_opt  */
#line 431 "ext/graphql_ext/parser.y"
                                                                            {
        result = make_node(:InputValueDefinition, name: val[1], type: val[3], default_value: val[4], directives: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2326 "ext/graphql_ext/parser.c"
    break;

  case 164: /* input_value_definition_list: input_value_definition  */
#line 436 "ext/graphql_ext/parser.y"
                                                         { result = [val[0]] }
#line 2332 "ext/graphql_ext/parser.c"
    break;

  case 165: /* input_value_definition_list: input_value_definition_list input_value_definition  */
#line 437 "ext/graphql_ext/parser.y"
                                                         { val[0] << val[1] }
#line 2338 "ext/graphql_ext/parser.c"
    break;

  case 166: /* arguments_definitions_opt: %empty  */
#line 440 "ext/graphql_ext/parser.y"
                 { result = EMPTY_ARRAY }
#line 2344 "ext/graphql_ext/parser.c"
    break;

  case 167: /* arguments_definitions_opt: LPAREN input_value_definition_list RPAREN  */
#line 441 "ext/graphql_ext/parser.y"
                                                { result = val[1] }
#line 2350 "ext/graphql_ext/parser.c"
    break;

  case 168: /* field_definition: description_opt name arguments_definitions_opt COLON type directives_list_opt  */
#line 444 "ext/graphql_ext/parser.y"
                                                                                    {
        result = make_node(:FieldDefinition, name: val[1], arguments: val[2], type: val[4], directives: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2358 "ext/graphql_ext/parser.c"
    break;

  case 169: /* field_definition_list_opt: %empty  */
#line 449 "ext/graphql_ext/parser.y"
               { result = EMPTY_ARRAY }
#line 2364 "ext/graphql_ext/parser.c"
    break;

  case 170: /* field_definition_list_opt: LCURLY field_definition_list RCURLY  */
#line 450 "ext/graphql_ext/parser.y"
                                          { result = val[1] }
#line 2370 "ext/graphql_ext/parser.c"
    break;

  case 171: /* field_definition_list: %empty  */
#line 453 "ext/graphql_ext/parser.y"
                                                                                { result = EMPTY_ARRAY }
#line 2376 "ext/graphql_ext/parser.c"
    break;

  case 172: /* field_definition_list: field_definition  */
#line 454 "ext/graphql_ext/parser.y"
                                             { result = [val[0]] }
#line 2382 "ext/graphql_ext/parser.c"
    break;

  case 173: /* field_definition_list: field_definition_list field_definition  */
#line 455 "ext/graphql_ext/parser.y"
                                             { val[0] << val[1] }
#line 2388 "ext/graphql_ext/parser.c"
    break;

  case 174: /* interface_type_definition: description_opt INTERFACE name implements_opt directives_list_opt field_definition_list_opt  */
#line 458 "ext/graphql_ext/parser.y"
                                                                                                  {
        result = make_node(:InterfaceTypeDefinition, name: val[2], interfaces: val[3], directives: val[4], fields: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2396 "ext/graphql_ext/parser.c"
    break;

  case 175: /* union_members: name  */
#line 463 "ext/graphql_ext/parser.y"
                              { result = [make_node(:TypeName, name: val[0], position_source: val[0])]}
#line 2402 "ext/graphql_ext/parser.c"
    break;

  case 176: /* union_members: union_members PIPE name  */
#line 464 "ext/graphql_ext/parser.y"
                              { val[0] << make_node(:TypeName, name: val[2], position_source: val[2]) }
#line 2408 "ext/graphql_ext/parser.c"
    break;

  case 177: /* union_type_definition: description_opt UNION name directives_list_opt EQUALS union_members  */
#line 467 "ext/graphql_ext/parser.y"
                                                                          {
        result = make_node(:UnionTypeDefinition, name: val[2], directives: val[3], types: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2416 "ext/graphql_ext/parser.c"
    break;

  case 178: /* enum_type_definition: description_opt ENUM name directives_list_opt LCURLY enum_value_definitions RCURLY  */
#line 472 "ext/graphql_ext/parser.y"
                                                                                         {
         result = make_node(:EnumTypeDefinition, name: val[2], directives: val[3], values: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2424 "ext/graphql_ext/parser.c"
    break;

  case 179: /* input_object_type_definition: description_opt INPUT name directives_list_opt LCURLY input_value_definition_list RCURLY  */
#line 477 "ext/graphql_ext/parser.y"
                                                                                               {
        result = make_node(:InputObjectTypeDefinition, name: val[2], directives: val[3], fields: val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2432 "ext/graphql_ext/parser.c"
    break;

  case 180: /* directive_definition: description_opt DIRECTIVE DIR_SIGN name arguments_definitions_opt directive_repeatable_opt ON directive_locations  */
#line 482 "ext/graphql_ext/parser.y"
                                                                                                                        {
        result = make_node(:DirectiveDefinition, name: val[3], arguments: val[4], locations: val[7], repeatable: !!val[5], description: val[0] || get_description(val[1]), definition_line: val[1][1], position_source: val[0] || val[1])
      }
#line 2440 "ext/graphql_ext/parser.c"
    break;

  case 183: /* directive_locations: name  */
#line 491 "ext/graphql_ext/parser.y"
                                    { result = [make_node(:DirectiveLocation, name: val[0][3], position_source: val[0])] }
#line 2446 "ext/graphql_ext/parser.c"
    break;

  case 184: /* directive_locations: directive_locations PIPE name  */
#line 492 "ext/graphql_ext/parser.y"
                                    { val[0] << make_node(:DirectiveLocation, name: val[2][3], position_source: val[2]) }
#line 2452 "ext/graphql_ext/parser.c"
    break;


#line 2456 "ext/graphql_ext/parser.c"

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
      yyerror (YY_("syntax error"));
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
                      yytoken, &yylval);
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
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
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
  yyerror (YY_("memory exhausted"));
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
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 494 "ext/graphql_ext/parser.y"


// Custom functions
int
yylex (YYSTYPE *lvalp)
{
  *lvalp = value;  /* Put value onto Bison stack. */
  return INT;      /* Return the kind of the token. */
}
