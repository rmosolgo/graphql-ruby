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
#define YYSTYPE VALUE
int yylex(YYSTYPE *, VALUE);
void yyerror(VALUE, const char*);


#line 80 "ext/graphql_ext/parser.c"

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
  YYSYMBOL_selection_list = 47,            /* selection_list  */
  YYSYMBOL_selection = 48,                 /* selection  */
  YYSYMBOL_selection_set = 49,             /* selection_set  */
  YYSYMBOL_selection_set_opt = 50,         /* selection_set_opt  */
  YYSYMBOL_field = 51,                     /* field  */
  YYSYMBOL_arguments_opt = 52,             /* arguments_opt  */
  YYSYMBOL_arguments_list = 53,            /* arguments_list  */
  YYSYMBOL_argument = 54,                  /* argument  */
  YYSYMBOL_literal_value = 55,             /* literal_value  */
  YYSYMBOL_input_value = 56,               /* input_value  */
  YYSYMBOL_null_value = 57,                /* null_value  */
  YYSYMBOL_variable = 58,                  /* variable  */
  YYSYMBOL_list_value = 59,                /* list_value  */
  YYSYMBOL_list_value_list = 60,           /* list_value_list  */
  YYSYMBOL_enum_name = 61,                 /* enum_name  */
  YYSYMBOL_enum_value = 62,                /* enum_value  */
  YYSYMBOL_object_value = 63,              /* object_value  */
  YYSYMBOL_object_value_list_opt = 64,     /* object_value_list_opt  */
  YYSYMBOL_object_value_list = 65,         /* object_value_list  */
  YYSYMBOL_object_value_field = 66,        /* object_value_field  */
  YYSYMBOL_object_literal_value = 67,      /* object_literal_value  */
  YYSYMBOL_object_literal_value_list_opt = 68, /* object_literal_value_list_opt  */
  YYSYMBOL_object_literal_value_list = 69, /* object_literal_value_list  */
  YYSYMBOL_object_literal_value_field = 70, /* object_literal_value_field  */
  YYSYMBOL_directives_list_opt = 71,       /* directives_list_opt  */
  YYSYMBOL_directives_list = 72,           /* directives_list  */
  YYSYMBOL_directive = 73,                 /* directive  */
  YYSYMBOL_name = 74,                      /* name  */
  YYSYMBOL_operation_type = 75,            /* operation_type  */
  YYSYMBOL_schema_keyword = 76,            /* schema_keyword  */
  YYSYMBOL_name_without_on = 77            /* name_without_on  */
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
typedef yytype_int8 yy_state_t;

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
#define YYFINAL  34
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   367

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  40
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  38
/* YYNRULES -- Number of rules.  */
#define YYNRULES  86
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  113

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
       0,    57,    57,    59,    62,    63,    66,    72,    91,   100,
     111,   112,   115,   120,   123,   124,   129,   142,   157,   158,
     161,   162,   165,   176,   177,   178,   179,   180,   181,   182,
     183,   184,   187,   188,   189,   191,   200,   210,   211,   214,
     215,   218,   219,   220,   221,   222,   223,   225,   234,   235,
     245,   246,   249,   250,   253,   265,   275,   276,   279,   280,
     283,   295,   296,   299,   300,   302,   313,   314,   317,   318,
     319,   322,   323,   324,   325,   326,   327,   328,   329,   330,
     333,   334,   335,   336,   337,   338,   339
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
  "operation_definition", "selection_list", "selection", "selection_set",
  "selection_set_opt", "field", "arguments_opt", "arguments_list",
  "argument", "literal_value", "input_value", "null_value", "variable",
  "list_value", "list_value_list", "enum_name", "enum_value",
  "object_value", "object_value_list_opt", "object_value_list",
  "object_value_field", "object_literal_value",
  "object_literal_value_list_opt", "object_literal_value_list",
  "object_literal_value_field", "directives_list_opt", "directives_list",
  "directive", "name", "operation_type", "schema_keyword",
  "name_without_on", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-97)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     -10,   197,    13,   -97,   -10,   -97,   -97,   -97,   -97,   -97,
     -97,   -97,   -97,   -97,   -97,   -97,   -97,   -97,   -97,   -97,
     -97,   -97,   -97,   -97,   -97,   -97,   -97,   230,   -97,   -97,
       0,   -97,   -97,   -97,   -97,   -97,   -97,   -97,   329,   329,
       7,    -6,   263,   -97,    12,   329,    -2,     7,   -97,     7,
     -97,   -97,   130,    -6,   329,   -97,   -97,   -97,    -2,   -97,
     -97,   -97,   -97,   -97,    62,   329,   -97,   -97,   -97,   -97,
     -97,   329,   -97,   -97,   -97,   -97,   -97,   -97,   -97,   -97,
     -97,   -97,   -97,   -97,   296,   -97,   -97,   -97,    96,    -5,
     329,   -97,    -4,   329,   -97,    18,   -97,   -97,   -97,   -97,
     -97,   -97,    21,   -97,   -97,    23,   130,   130,   164,   -97,
     -97,   329,   -97
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       0,     0,     0,     2,     3,     4,     6,     7,    79,    77,
      84,    81,    80,    78,    74,    75,    69,    67,    68,     9,
      82,    72,    71,    70,    83,    73,    76,     0,    10,    12,
      18,    85,    86,    66,     1,     5,     8,    11,     0,     0,
      61,    18,     0,    20,     0,     0,    14,    62,    63,    61,
      19,    21,    48,    18,     0,    15,    17,    64,    14,    27,
      23,    42,    41,    24,     0,    50,    35,    44,    43,    25,
      26,     0,    32,    22,    28,    33,    30,    47,    29,    34,
      31,    45,    46,    65,     0,    16,    37,    39,     0,     0,
      51,    52,     0,    57,    58,     0,    36,    13,    38,    40,
      49,    53,     0,    55,    59,     0,    48,    48,     0,    32,
      54,    56,    60
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int8 yypgoto[] =
{
     -97,   -97,   -97,   -97,    25,   -97,   -97,   -24,   -25,   -97,
     -27,   -97,   -33,   -97,    -8,   -96,   -49,   -97,   -97,   -97,
     -97,   -97,   -97,   -97,   -97,   -97,   -58,   -97,   -97,   -97,
     -57,   -14,   -97,    -9,   -38,   -46,   -43,   -97
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int8 yydefgoto[] =
{
       0,     2,     3,     4,     5,     6,     7,    27,    28,    55,
      56,    29,    40,    42,    43,    72,   110,    74,    75,    76,
      88,    77,    78,    79,    89,    90,    91,    80,    92,    93,
      94,    46,    47,    48,    30,    31,    32,    33
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_int8 yytable[] =
{
      41,    44,    37,    73,    44,    38,    81,    53,    49,    82,
     109,     1,   112,    34,    45,    87,    39,    52,    81,    54,
      83,    82,    39,   106,   100,   103,   107,    95,   108,    35,
      84,    85,   101,    96,    51,    58,   104,     0,    57,    99,
       0,     0,    81,     0,     0,    82,     0,     0,     0,     0,
       0,     0,   102,     0,     0,   105,     0,     0,     0,    37,
      81,    81,    81,    82,    82,    82,     0,     0,     8,     0,
       9,     0,     0,   105,    59,    60,    61,    62,    13,    14,
      63,    15,    64,    65,     0,    16,    66,    67,     0,    18,
      86,     0,    68,     0,    21,    22,    69,    23,    70,    25,
      26,    71,     8,     0,     9,     0,     0,     0,    59,    60,
      61,    62,    13,    14,    63,    15,    64,    65,     0,    16,
      66,    67,     0,    18,    98,     0,    68,     0,    21,    22,
      69,    23,    70,    25,    26,    71,     8,     0,     9,     0,
       0,     0,    59,    60,    61,    62,    13,    14,    63,    15,
      64,    65,     0,    16,    66,    67,     0,    18,     0,     0,
      68,     0,    21,    22,    69,    23,    70,    25,    26,    71,
       8,     0,     9,     0,     0,     0,    59,    60,    61,    62,
      13,    14,    63,    15,    64,   111,     0,    16,    66,    67,
       0,    18,     0,     0,    68,     0,    21,    22,    69,    23,
      70,    25,    26,     8,     0,     9,     0,     0,     0,    10,
       0,    11,    12,    13,    14,     0,    15,     0,     0,     0,
      16,     0,    17,     0,    18,     0,    19,    20,     0,    21,
      22,     0,    23,    24,    25,    26,     8,     0,     9,     0,
       0,     0,    10,     0,    11,    12,    13,    14,     0,    15,
       0,     0,     0,    16,     0,    17,     0,    18,     0,    36,
      20,     0,    21,    22,     0,    23,    24,    25,    26,     8,
       0,     9,     0,     0,     0,    10,     0,    11,    12,    13,
      14,     0,    15,     0,     0,     0,    16,     0,    17,     0,
      18,     0,     0,    20,    50,    21,    22,     0,    23,    24,
      25,    26,     8,     0,     9,     0,     0,     0,    10,     0,
      11,    12,    13,    14,     0,    15,     0,     0,     0,    16,
       0,    17,     0,    18,     0,    97,    20,     0,    21,    22,
       0,    23,    24,    25,    26,     8,     0,     9,     0,     0,
       0,    10,     0,    11,    12,    13,    14,     0,    15,     0,
       0,     0,    16,     0,    17,     0,    18,     0,     0,    20,
       0,    21,    22,     0,    23,    24,    25,    26
};

static const yytype_int8 yycheck[] =
{
      38,    39,    27,    52,    42,     5,    52,    45,    41,    52,
     106,    21,   108,     0,     7,    64,    22,     5,    64,    21,
      53,    64,    22,     5,    29,    29,     5,    65,     5,     4,
      54,    58,    90,    71,    42,    49,    93,    -1,    47,    88,
      -1,    -1,    88,    -1,    -1,    88,    -1,    -1,    -1,    -1,
      -1,    -1,    90,    -1,    -1,    93,    -1,    -1,    -1,    84,
     106,   107,   108,   106,   107,   108,    -1,    -1,     6,    -1,
       8,    -1,    -1,   111,    12,    13,    14,    15,    16,    17,
      18,    19,    20,    21,    -1,    23,    24,    25,    -1,    27,
      28,    -1,    30,    -1,    32,    33,    34,    35,    36,    37,
      38,    39,     6,    -1,     8,    -1,    -1,    -1,    12,    13,
      14,    15,    16,    17,    18,    19,    20,    21,    -1,    23,
      24,    25,    -1,    27,    28,    -1,    30,    -1,    32,    33,
      34,    35,    36,    37,    38,    39,     6,    -1,     8,    -1,
      -1,    -1,    12,    13,    14,    15,    16,    17,    18,    19,
      20,    21,    -1,    23,    24,    25,    -1,    27,    -1,    -1,
      30,    -1,    32,    33,    34,    35,    36,    37,    38,    39,
       6,    -1,     8,    -1,    -1,    -1,    12,    13,    14,    15,
      16,    17,    18,    19,    20,    21,    -1,    23,    24,    25,
      -1,    27,    -1,    -1,    30,    -1,    32,    33,    34,    35,
      36,    37,    38,     6,    -1,     8,    -1,    -1,    -1,    12,
      -1,    14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,
      23,    -1,    25,    -1,    27,    -1,    29,    30,    -1,    32,
      33,    -1,    35,    36,    37,    38,     6,    -1,     8,    -1,
      -1,    -1,    12,    -1,    14,    15,    16,    17,    -1,    19,
      -1,    -1,    -1,    23,    -1,    25,    -1,    27,    -1,    29,
      30,    -1,    32,    33,    -1,    35,    36,    37,    38,     6,
      -1,     8,    -1,    -1,    -1,    12,    -1,    14,    15,    16,
      17,    -1,    19,    -1,    -1,    -1,    23,    -1,    25,    -1,
      27,    -1,    -1,    30,    31,    32,    33,    -1,    35,    36,
      37,    38,     6,    -1,     8,    -1,    -1,    -1,    12,    -1,
      14,    15,    16,    17,    -1,    19,    -1,    -1,    -1,    23,
      -1,    25,    -1,    27,    -1,    29,    30,    -1,    32,    33,
      -1,    35,    36,    37,    38,     6,    -1,     8,    -1,    -1,
      -1,    12,    -1,    14,    15,    16,    17,    -1,    19,    -1,
      -1,    -1,    23,    -1,    25,    -1,    27,    -1,    -1,    30,
      -1,    32,    33,    -1,    35,    36,    37,    38
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    21,    41,    42,    43,    44,    45,    46,     6,     8,
      12,    14,    15,    16,    17,    19,    23,    25,    27,    29,
      30,    32,    33,    35,    36,    37,    38,    47,    48,    51,
      74,    75,    76,    77,     0,    44,    29,    48,     5,    22,
      52,    74,    53,    54,    74,     7,    71,    72,    73,    52,
      31,    54,     5,    74,    21,    49,    50,    73,    71,    12,
      13,    14,    15,    18,    20,    21,    24,    25,    30,    34,
      36,    39,    55,    56,    57,    58,    59,    61,    62,    63,
      67,    75,    76,    52,    47,    50,    28,    56,    60,    64,
      65,    66,    68,    69,    70,    74,    74,    29,    28,    56,
      29,    66,    74,    29,    70,    74,     5,     5,     5,    55,
      56,    21,    55
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    40,    41,    42,    43,    43,    44,    45,    46,    46,
      47,    47,    48,    49,    50,    50,    51,    51,    52,    52,
      53,    53,    54,    55,    55,    55,    55,    55,    55,    55,
      55,    55,    56,    56,    56,    57,    58,    59,    59,    60,
      60,    61,    61,    61,    61,    61,    61,    62,    63,    63,
      64,    64,    65,    65,    66,    67,    68,    68,    69,    69,
      70,    71,    71,    72,    72,    73,    74,    74,    75,    75,
      75,    76,    76,    76,    76,    76,    76,    76,    76,    76,
      77,    77,    77,    77,    77,    77,    77
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     1,     1,     1,     2,     1,     1,     3,     2,
       1,     2,     1,     3,     0,     1,     6,     4,     0,     3,
       1,     2,     3,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     2,     2,     3,     1,
       2,     1,     1,     1,     1,     1,     1,     1,     0,     3,
       0,     1,     1,     2,     3,     3,     0,     1,     1,     2,
       3,     0,     1,     1,     2,     3,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1,     1,     1,     1,
       1,     1,     1,     1,     1,     1,     1
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
#line 57 "ext/graphql_ext/parser.y"
                  { rb_ivar_set(parser, rb_intern("result"), yyvsp[0]); }
#line 1403 "ext/graphql_ext/parser.c"
    break;

  case 3: /* document: definitions_list  */
#line 59 "ext/graphql_ext/parser.y"
                             { yyval = yyvsp[0]; }
#line 1409 "ext/graphql_ext/parser.c"
    break;

  case 4: /* definitions_list: definition  */
#line 62 "ext/graphql_ext/parser.y"
                                    { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1415 "ext/graphql_ext/parser.c"
    break;

  case 5: /* definitions_list: definitions_list definition  */
#line 63 "ext/graphql_ext/parser.y"
                                    { rb_ary_push(yyval, yyvsp[0]); }
#line 1421 "ext/graphql_ext/parser.c"
    break;

  case 8: /* operation_definition: LCURLY selection_list RCURLY  */
#line 91 "ext/graphql_ext/parser.y"
                                 {
        yyval = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("OperationDefinition")),
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_str_new_cstr("query"), // TODO static string
          yyvsp[-1]
        );
      }
#line 1435 "ext/graphql_ext/parser.c"
    break;

  case 9: /* operation_definition: LCURLY RCURLY  */
#line 100 "ext/graphql_ext/parser.y"
                    {
        yyval = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("OperationDefinition")),
          rb_ary_entry(yyvsp[-1], 1),
          rb_ary_entry(yyvsp[-1], 2),
          rb_str_new_cstr("query"), // TODO static string
          rb_ary_new()
        );
      }
#line 1449 "ext/graphql_ext/parser.c"
    break;

  case 10: /* selection_list: selection  */
#line 111 "ext/graphql_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1455 "ext/graphql_ext/parser.c"
    break;

  case 11: /* selection_list: selection_list selection  */
#line 112 "ext/graphql_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 1461 "ext/graphql_ext/parser.c"
    break;

  case 13: /* selection_set: LCURLY selection_list RCURLY  */
#line 120 "ext/graphql_ext/parser.y"
                                   { yyval = yyvsp[-1]; }
#line 1467 "ext/graphql_ext/parser.c"
    break;

  case 14: /* selection_set_opt: %empty  */
#line 123 "ext/graphql_ext/parser.y"
                    { yyval = rb_ary_new(); }
#line 1473 "ext/graphql_ext/parser.c"
    break;

  case 16: /* field: name COLON name arguments_opt directives_list_opt selection_set_opt  */
#line 129 "ext/graphql_ext/parser.y"
                                                                        {
      yyval = rb_ary_new_from_args(
        8,
        rb_id2sym(rb_intern("Field")),
        rb_ary_entry(yyvsp[-5], 1),
        rb_ary_entry(yyvsp[-5], 2),
        rb_ary_entry(yyvsp[-5], 3), // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 1491 "ext/graphql_ext/parser.c"
    break;

  case 17: /* field: name arguments_opt directives_list_opt selection_set_opt  */
#line 142 "ext/graphql_ext/parser.y"
                                                               {
      yyval = rb_ary_new_from_args(
        8,
        rb_id2sym(rb_intern("Field")),
        rb_ary_entry(yyvsp[-3], 1),
        rb_ary_entry(yyvsp[-3], 2),
        Qnil, // alias
        rb_ary_entry(yyvsp[-3], 3), // name
        yyvsp[-2], // args
        yyvsp[-1], // directives
        yyvsp[0] // subselections
      );
    }
#line 1509 "ext/graphql_ext/parser.c"
    break;

  case 18: /* arguments_opt: %empty  */
#line 157 "ext/graphql_ext/parser.y"
                                    { yyval = Qnil; }
#line 1515 "ext/graphql_ext/parser.c"
    break;

  case 19: /* arguments_opt: LPAREN arguments_list RPAREN  */
#line 158 "ext/graphql_ext/parser.y"
                                    { yyval = yyvsp[-1]; }
#line 1521 "ext/graphql_ext/parser.c"
    break;

  case 20: /* arguments_list: argument  */
#line 161 "ext/graphql_ext/parser.y"
                              { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1527 "ext/graphql_ext/parser.c"
    break;

  case 21: /* arguments_list: arguments_list argument  */
#line 162 "ext/graphql_ext/parser.y"
                              { rb_ary_push(yyval, yyvsp[0]); }
#line 1533 "ext/graphql_ext/parser.c"
    break;

  case 22: /* argument: name COLON input_value  */
#line 165 "ext/graphql_ext/parser.y"
                             {
        yyval = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("Argument")),
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          yyvsp[0]
        );
      }
#line 1547 "ext/graphql_ext/parser.c"
    break;

  case 23: /* literal_value: FLOAT  */
#line 176 "ext/graphql_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_f"), 0); }
#line 1553 "ext/graphql_ext/parser.c"
    break;

  case 24: /* literal_value: INT  */
#line 177 "ext/graphql_ext/parser.y"
                  { yyval = rb_funcall(rb_ary_entry(yyvsp[0], 3), rb_intern("to_i"), 0); }
#line 1559 "ext/graphql_ext/parser.c"
    break;

  case 25: /* literal_value: STRING  */
#line 178 "ext/graphql_ext/parser.y"
                  { yyval = rb_ary_entry(yyvsp[0], 3); }
#line 1565 "ext/graphql_ext/parser.c"
    break;

  case 26: /* literal_value: TRUE_LITERAL  */
#line 179 "ext/graphql_ext/parser.y"
                          { yyval = Qtrue; }
#line 1571 "ext/graphql_ext/parser.c"
    break;

  case 27: /* literal_value: FALSE_LITERAL  */
#line 180 "ext/graphql_ext/parser.y"
                          { yyval = Qfalse; }
#line 1577 "ext/graphql_ext/parser.c"
    break;

  case 35: /* null_value: NULL_LITERAL  */
#line 191 "ext/graphql_ext/parser.y"
                           {
    yyval = rb_ary_new_from_args(4,
      rb_id2sym(rb_intern("NullValue")),
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 1590 "ext/graphql_ext/parser.c"
    break;

  case 36: /* variable: VAR_SIGN name  */
#line 200 "ext/graphql_ext/parser.y"
                          {
    yyval = rb_ary_new_from_args(4,
      rb_id2sym(rb_intern("VariableIdentifier")),
      rb_ary_entry(yyvsp[-1], 1),
      rb_ary_entry(yyvsp[-1], 2),
      rb_ary_entry(yyvsp[-1], 3)
    );
  }
#line 1603 "ext/graphql_ext/parser.c"
    break;

  case 37: /* list_value: LBRACKET RBRACKET  */
#line 210 "ext/graphql_ext/parser.y"
                                        { yyval = rb_ary_new(); }
#line 1609 "ext/graphql_ext/parser.c"
    break;

  case 38: /* list_value: LBRACKET list_value_list RBRACKET  */
#line 211 "ext/graphql_ext/parser.y"
                                        { yyval = yyvsp[-1]; }
#line 1615 "ext/graphql_ext/parser.c"
    break;

  case 39: /* list_value_list: input_value  */
#line 214 "ext/graphql_ext/parser.y"
                                  { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1621 "ext/graphql_ext/parser.c"
    break;

  case 40: /* list_value_list: list_value_list input_value  */
#line 215 "ext/graphql_ext/parser.y"
                                  { rb_ary_push(yyval, yyvsp[0]); }
#line 1627 "ext/graphql_ext/parser.c"
    break;

  case 47: /* enum_value: enum_name  */
#line 225 "ext/graphql_ext/parser.y"
                        {
    yyval = rb_ary_new_from_args(4,
      rb_id2sym(rb_intern("Enum")),
      rb_ary_entry(yyvsp[0], 1),
      rb_ary_entry(yyvsp[0], 2),
      rb_ary_entry(yyvsp[0], 3)
    );
  }
#line 1640 "ext/graphql_ext/parser.c"
    break;

  case 49: /* object_value: LCURLY object_value_list_opt RCURLY  */
#line 235 "ext/graphql_ext/parser.y"
                                          {
      yyval = rb_ary_new_from_args(4,
        rb_id2sym(rb_intern("InputObject")),
        rb_ary_entry(yyvsp[-2], 1),
        rb_ary_entry(yyvsp[-2], 2),
        yyvsp[-1]
      );
    }
#line 1653 "ext/graphql_ext/parser.c"
    break;

  case 50: /* object_value_list_opt: %empty  */
#line 245 "ext/graphql_ext/parser.y"
                        { yyval = rb_ary_new(); }
#line 1659 "ext/graphql_ext/parser.c"
    break;

  case 52: /* object_value_list: object_value_field  */
#line 249 "ext/graphql_ext/parser.y"
                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1665 "ext/graphql_ext/parser.c"
    break;

  case 53: /* object_value_list: object_value_list object_value_field  */
#line 250 "ext/graphql_ext/parser.y"
                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 1671 "ext/graphql_ext/parser.c"
    break;

  case 54: /* object_value_field: name COLON input_value  */
#line 253 "ext/graphql_ext/parser.y"
                             {
        yyval = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("Argument")),
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 1685 "ext/graphql_ext/parser.c"
    break;

  case 55: /* object_literal_value: LCURLY object_literal_value_list_opt RCURLY  */
#line 265 "ext/graphql_ext/parser.y"
                                                  {
        yyval = rb_ary_new_from_args(4,
          rb_id2sym(rb_intern("InputObject")),
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          yyvsp[-1]
        );
      }
#line 1698 "ext/graphql_ext/parser.c"
    break;

  case 56: /* object_literal_value_list_opt: %empty  */
#line 275 "ext/graphql_ext/parser.y"
                                { yyval = rb_ary_new(); }
#line 1704 "ext/graphql_ext/parser.c"
    break;

  case 58: /* object_literal_value_list: object_literal_value_field  */
#line 279 "ext/graphql_ext/parser.y"
                                                            { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1710 "ext/graphql_ext/parser.c"
    break;

  case 59: /* object_literal_value_list: object_literal_value_list object_literal_value_field  */
#line 280 "ext/graphql_ext/parser.y"
                                                            { rb_ary_push(yyval, yyvsp[0]); }
#line 1716 "ext/graphql_ext/parser.c"
    break;

  case 60: /* object_literal_value_field: name COLON literal_value  */
#line 283 "ext/graphql_ext/parser.y"
                               {
        yyval = rb_ary_new_from_args(5,
          rb_id2sym(rb_intern("Argument")),
          rb_ary_entry(yyvsp[-2], 1),
          rb_ary_entry(yyvsp[-2], 2),
          rb_ary_entry(yyvsp[-2], 3),
          rb_ary_entry(yyvsp[0], 3)
        );
      }
#line 1730 "ext/graphql_ext/parser.c"
    break;

  case 61: /* directives_list_opt: %empty  */
#line 295 "ext/graphql_ext/parser.y"
                      { yyval = rb_ary_new(); }
#line 1736 "ext/graphql_ext/parser.c"
    break;

  case 63: /* directives_list: directive  */
#line 299 "ext/graphql_ext/parser.y"
                                { yyval = rb_ary_new_from_args(1, yyvsp[0]); }
#line 1742 "ext/graphql_ext/parser.c"
    break;

  case 64: /* directives_list: directives_list directive  */
#line 300 "ext/graphql_ext/parser.y"
                                { rb_ary_push(yyval, yyvsp[0]); }
#line 1748 "ext/graphql_ext/parser.c"
    break;

  case 65: /* directive: DIR_SIGN name arguments_opt  */
#line 302 "ext/graphql_ext/parser.y"
                                         {
    yyval = rb_ary_new_from_args(5,
      rb_id2sym(rb_intern("Directive")),
      rb_ary_entry(yyvsp[-2], 1),
      rb_ary_entry(yyvsp[-2], 2),
      rb_ary_entry(yyvsp[-1], 3),
      yyvsp[0]
    );
  }
#line 1762 "ext/graphql_ext/parser.c"
    break;


#line 1766 "ext/graphql_ext/parser.c"

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
      yyerror (parser, YY_("syntax error"));
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

  return yyresult;
}

#line 340 "ext/graphql_ext/parser.y"


// Custom functions
int yylex (YYSTYPE *lvalp, VALUE parser) {
  int next_token_idx = FIX2INT(rb_ivar_get(parser, rb_intern("current_token")));
  VALUE tokens = rb_ivar_get(parser, rb_intern("tokens"));
  VALUE next_token = rb_ary_entry(tokens, next_token_idx);

  if (!RB_TEST(next_token)) {
    return YYEOF;
  }

  rb_ivar_set(parser, rb_intern("current_token"), INT2FIX(next_token_idx + 1));
  VALUE token_type_rb_int = rb_ary_entry(next_token, 5);
  int next_token_type = FIX2INT(token_type_rb_int);

  *lvalp = next_token;
  return next_token_type;
}

void yyerror(VALUE tokens, const char *msg) {
}
