#line 1 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

#line 113 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"



#line 8 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
static const char _graphql_c_lexer_trans_keys[] = {
	2, 2, 5, 25, 7, 46, 17, 50,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 52, 7, 25, 7, 7, 7, 7,
	7, 25, 7, 7, 7, 7, 17, 18,
	13, 18, 17, 18, 15, 15, 3, 52,
	0, 0, 4, 4, 5, 25, 7, 7,
	7, 7, 7, 7, 7, 25, 7, 7,
	7, 7, 5, 5, 17, 18, 15, 32,
	17, 32, 17, 18, 15, 32, 15, 15,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 49, 17, 49, 0
};

static const signed char _graphql_c_lexer_char_class[] = {
	0, 1, 1, 1, 2, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 3, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 4, 5,
	1, 1, 5, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 4, 6, 7,
	8, 9, 1, 10, 1, 11, 12, 1,
	13, 4, 14, 15, 16, 17, 18, 18,
	18, 18, 18, 18, 18, 18, 18, 19,
	1, 1, 20, 1, 1, 21, 22, 22,
	22, 22, 23, 22, 22, 22, 22, 22,
	22, 22, 22, 22, 22, 22, 22, 22,
	22, 22, 22, 22, 22, 22, 22, 22,
	24, 25, 26, 1, 27, 1, 28, 29,
	30, 31, 32, 33, 34, 35, 36, 22,
	22, 37, 38, 39, 40, 41, 42, 43,
	44, 45, 46, 47, 22, 48, 49, 22,
	50, 51, 52, 0
};

static const short _graphql_c_lexer_index_offsets[] = {
	0, 1, 22, 62, 96, 129, 162, 195,
	228, 264, 283, 284, 285, 304, 305, 306,
	308, 314, 316, 317, 367, 368, 369, 390,
	391, 392, 393, 412, 413, 414, 415, 417,
	435, 451, 453, 471, 472, 505, 538, 571,
	604, 637, 670, 703, 736, 769, 802, 835,
	868, 901, 934, 967, 1000, 1033, 1066, 1099,
	1132, 1165, 1198, 1231, 1264, 1297, 1330, 1363,
	1396, 1429, 1462, 1495, 1528, 1561, 1594, 1627,
	1660, 1693, 1726, 1759, 1792, 1825, 1858, 1891,
	1924, 1957, 1990, 2023, 2056, 2089, 2122, 2155,
	2188, 2221, 2254, 2287, 2320, 2353, 2386, 2419,
	2452, 2485, 2518, 2551, 2584, 2617, 2650, 2683,
	2716, 2749, 2782, 2815, 2848, 2881, 2914, 2947,
	2980, 3013, 3046, 3079, 3112, 3145, 3178, 3211,
	3244, 3277, 3310, 3343, 3376, 3409, 3442, 3475,
	3508, 3541, 3574, 0
};

static const short _graphql_c_lexer_indices[] = {
	1, 0, 2, 3, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 4, 2, 0,
	0, 0, 0, 0, 0, 0, 0, 2,
	0, 0, 0, 0, 0, 0, 0, 0,
	2, 0, 0, 0, 2, 0, 0, 0,
	2, 0, 0, 0, 0, 0, 2, 0,
	0, 0, 2, 0, 2, 5, 6, 6,
	0, 0, 0, 6, 6, 0, 0, 0,
	0, 6, 6, 6, 6, 6, 6, 6,
	6, 6, 6, 6, 6, 6, 6, 6,
	6, 6, 6, 6, 6, 6, 6, 7,
	8, 8, 0, 0, 0, 8, 8, 0,
	0, 0, 0, 8, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 9, 9, 0, 0, 0, 9, 9,
	0, 0, 0, 0, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 2, 2, 0, 0, 0, 2,
	2, 0, 0, 0, 0, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 10, 10, 0, 0, 0,
	10, 10, 0, 0, 0, 0, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 0, 0,
	0, 10, 10, 0, 0, 0, 0, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 0, 0, 2,
	13, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 14, 15, 16, 17, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 14,
	18, 19, 21, 21, 22, 22, 11, 11,
	23, 23, 23, 23, 24, 27, 28, 29,
	30, 31, 32, 33, 34, 35, 36, 26,
	37, 38, 26, 39, 40, 41, 42, 43,
	44, 44, 45, 26, 46, 44, 44, 44,
	44, 47, 48, 49, 44, 44, 50, 44,
	51, 52, 53, 44, 54, 55, 56, 57,
	58, 44, 44, 44, 59, 60, 61, 63,
	28, 62, 2, 65, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 4, 12, 68,
	69, 70, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 14, 71, 16, 72, 39,
	40, 74, 73, 73, 73, 73, 73, 73,
	73, 75, 73, 73, 73, 73, 73, 73,
	73, 73, 75, 21, 21, 76, 76, 76,
	76, 75, 76, 76, 76, 76, 76, 76,
	76, 76, 75, 23, 23, 74, 73, 40,
	40, 73, 73, 73, 73, 75, 73, 73,
	73, 73, 73, 73, 73, 73, 75, 77,
	44, 44, 11, 11, 11, 44, 44, 11,
	11, 11, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 79, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 80, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 81, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 82, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 83, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 84, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 85, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 86,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 87,
	44, 44, 44, 44, 44, 44, 44, 44,
	88, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 89,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	90, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	91, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 92, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 93, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 94, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 95, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 96, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 97, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 98, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 99, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 100,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 101, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 102, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 103, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 104, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 105, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 106,
	107, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 108, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	109, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 110, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 111, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 112, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 113, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 114, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 115, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 116, 44, 44, 44, 117,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 118, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 119, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 120, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 121, 44, 44, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 44,
	122, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 123, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 124,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 125, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 126, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 127, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 128, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 129, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 130, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	131, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	132, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	133, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	134, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 135, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 136, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 137, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 138,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 139, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 140, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 141, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 142, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 143, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 144, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 145, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 146, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 147, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 148, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 149, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 150, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 151, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	152, 44, 44, 44, 44, 44, 44, 153,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 154, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 155, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 156, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	157, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 158,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 159, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	160, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	161, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 162, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 163, 44, 44, 44, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 164, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 165, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 166, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 167, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 168, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 169, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	170, 44, 44, 44, 44, 44, 171, 44,
	44, 78, 78, 78, 44, 44, 78, 78,
	78, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 172, 44, 44, 44,
	44, 44, 78, 78, 78, 44, 44, 78,
	78, 78, 44, 44, 44, 44, 44, 173,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 78, 78, 78, 44, 44,
	78, 78, 78, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 174, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 78, 78, 78, 44,
	44, 78, 78, 78, 44, 44, 44, 44,
	44, 175, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 78, 78, 78,
	44, 44, 78, 78, 78, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 176, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 78, 78,
	78, 44, 44, 78, 78, 78, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 177,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 78,
	78, 78, 44, 44, 78, 78, 78, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 178, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 44,
	78, 78, 78, 44, 44, 78, 78, 78,
	44, 44, 44, 44, 44, 44, 44, 44,
	44, 44, 44, 44, 179, 44, 44, 44,
	44, 44, 44, 44, 44, 44, 44, 0
};

static const signed char _graphql_c_lexer_index_defaults[] = {
	0, 2, 0, 0, 0, 0, 0, 0,
	0, 12, 12, 12, 12, 12, 12, 20,
	11, 11, 0, 26, 62, 64, 2, 66,
	67, 67, 12, 12, 12, 32, 62, 73,
	76, 76, 73, 62, 11, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 78, 78, 78, 78, 78,
	78, 78, 78, 0
};

static const short _graphql_c_lexer_cond_targs[] = {
	19, 19, 1, 19, 2, 3, 4, 7,
	5, 6, 8, 19, 9, 10, 12, 11,
	24, 13, 14, 26, 19, 32, 17, 33,
	19, 19, 19, 20, 21, 19, 19, 22,
	29, 19, 19, 19, 19, 30, 35, 31,
	34, 19, 19, 19, 36, 19, 19, 37,
	45, 52, 62, 80, 87, 90, 91, 95,
	104, 122, 127, 19, 19, 19, 19, 0,
	19, 23, 19, 19, 25, 19, 27, 28,
	19, 19, 15, 16, 19, 18, 19, 38,
	39, 40, 41, 42, 43, 44, 36, 46,
	48, 47, 36, 49, 50, 51, 36, 53,
	56, 54, 55, 36, 57, 58, 59, 60,
	61, 36, 63, 71, 64, 65, 66, 67,
	68, 69, 70, 36, 72, 74, 73, 36,
	75, 76, 77, 78, 79, 36, 81, 82,
	83, 84, 85, 86, 36, 88, 89, 36,
	36, 92, 93, 94, 36, 96, 97, 98,
	99, 100, 101, 102, 103, 36, 105, 112,
	106, 109, 107, 108, 36, 110, 111, 36,
	113, 114, 115, 116, 117, 118, 119, 120,
	121, 36, 123, 125, 124, 36, 126, 36,
	128, 129, 130, 36, 0
};

static const signed char _graphql_c_lexer_cond_actions[] = {
	1, 2, 0, 3, 0, 0, 0, 0,
	0, 0, 0, 4, 0, 0, 0, 0,
	0, 0, 0, 5, 6, 7, 0, 0,
	8, 0, 11, 12, 0, 13, 14, 12,
	0, 15, 16, 17, 18, 0, 12, 19,
	19, 20, 21, 22, 23, 24, 25, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 26, 27, 28, 29, 0,
	30, 31, 32, 33, 0, 34, 5, 5,
	35, 36, 0, 0, 37, 0, 38, 0,
	0, 0, 0, 0, 0, 0, 39, 0,
	0, 0, 40, 0, 0, 0, 41, 0,
	0, 0, 0, 42, 0, 0, 0, 0,
	0, 43, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 44, 0, 0, 0, 45,
	0, 0, 0, 0, 0, 46, 0, 0,
	0, 0, 0, 0, 47, 0, 0, 48,
	49, 0, 0, 0, 50, 0, 0, 0,
	0, 0, 0, 0, 0, 51, 0, 0,
	0, 0, 0, 0, 52, 0, 0, 53,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 54, 0, 0, 0, 55, 0, 56,
	0, 0, 0, 57, 0
};

static const signed char _graphql_c_lexer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 9, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0
};

static const signed char _graphql_c_lexer_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 10, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0
};

static const signed char _graphql_c_lexer_eof_trans[] = {
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 12, 12, 12, 12, 12, 12, 21,
	12, 12, 1, 26, 63, 65, 63, 67,
	68, 68, 68, 68, 68, 73, 63, 74,
	77, 77, 74, 63, 12, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 79, 79, 79, 79, 79,
	79, 79, 79, 0
};

static const int graphql_c_lexer_start = 19;
static const int graphql_c_lexer_first_final = 19;
static const int graphql_c_lexer_error = -1;

static const int graphql_c_lexer_en_main = 19;


#line 115 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"


#include <ruby.h>
#include <ruby/encoding.h>

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
INIT_STATIC_TOKEN_VARIABLE(EXTEND)
INIT_STATIC_TOKEN_VARIABLE(IMPLEMENTS)
INIT_STATIC_TOKEN_VARIABLE(INTERFACE)
INIT_STATIC_TOKEN_VARIABLE(UNION)
INIT_STATIC_TOKEN_VARIABLE(ENUM)
INIT_STATIC_TOKEN_VARIABLE(DIRECTIVE)
INIT_STATIC_TOKEN_VARIABLE(INPUT)

static VALUE GraphQL_type_str;
static VALUE GraphQL_true_str;
static VALUE GraphQL_false_str;
static VALUE GraphQL_null_str;
typedef enum GraphQLTokenType {
	AMP,
	BANG,
	COLON,
	DIRECTIVE,
	DIR_SIGN,
	ENUM,
	ELLIPSIS,
	EQUALS,
	EXTEND,
	FALSE_LITERAL,
	FLOAT_LITERAL,
	FRAGMENT,
	IDENTIFIER,
	INPUT_LITERAL,
	IMPLEMENTS,
	INT_LITERAL,
	INTERFACE_LITERAL,
	LBRACKET,
	LCURLY,
	LPAREN,
	MUTATION,
	NULL_LITERAL,
	ON,
	PIPE,
	QUERY,
	RBRACKET,
	RCURLY,
	REPEATABLE,
	RPAREN,
	SCALAR,
	SCHEMA,
	STRING,
	SUBSCRIPTION,
	TRUE_LITERAL,
	TYPE_LITERAL,
	UNION,
	VAR_SIGN,
	BLOCK_STRING,
	QUOTED_STRING,
	UNKNOWN_CHAR,
	COMMENT,
	BAD_UNICODE_ESCAPE
} GraphQLTokenType;

typedef struct Meta {
	int line;
	int col;
	char *query_cstr;
	char *pe;
	VALUE tokens;
	int dedup_identifiers;
	int reject_numbers_followed_by_names;
	int preceeded_by_number;
	int max_tokens;
	int tokens_count;
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

void emit(GraphQLTokenType tt, char *ts, char *te, Meta *meta) {
	meta->tokens_count++;
	// -1 indicates that there is no limit:
	if (meta->max_tokens > 0 && meta->tokens_count > meta->max_tokens) {
		VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
		VALUE cParseError = rb_const_get_at(mGraphQL, rb_intern("ParseError"));
		VALUE exception = rb_funcall(
		cParseError, rb_intern("new"), 4,
		rb_str_new_cstr("This query is too large to execute."),
		LONG2NUM(meta->line),
		LONG2NUM(meta->col),
		rb_str_new_cstr(meta->query_cstr)
		);
		rb_exc_raise(exception);
	}
	int quotes_length = 0; // set by string tokens below
	int line_incr = 0;
	int next_col = meta->col + (te - ts);
	VALUE token_sym = Qnil;
	VALUE token_content = Qnil;
	int this_token_is_number = 0;
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
		STATIC_VALUE_TOKEN(EXTEND, "extend")
		STATIC_VALUE_TOKEN(IMPLEMENTS, "implements")
		STATIC_VALUE_TOKEN(UNION, "union")
		STATIC_VALUE_TOKEN(ENUM, "enum")
		STATIC_VALUE_TOKEN(DIRECTIVE, "directive")
		// For these, the enum name doesn't match the symbol name:
		case INTERFACE_LITERAL:
		token_sym = ID2SYM(rb_intern("INTERFACE"));
		token_content = GraphQLTokenStringINTERFACE;
		break;
		case INPUT_LITERAL:
		token_sym = ID2SYM(rb_intern("INPUT"));
		token_content = GraphQLTokenStringINPUT;
		break;
		case TYPE_LITERAL:
		token_sym = ID2SYM(rb_intern("TYPE"));
		token_content = GraphQL_type_str;
		break;
		case TRUE_LITERAL:
		token_sym = ID2SYM(rb_intern("TRUE"));
		token_content = GraphQL_true_str;
		break;
		case FALSE_LITERAL:
		token_sym = ID2SYM(rb_intern("FALSE"));
		token_content = GraphQL_false_str;
		break;
		case NULL_LITERAL:
		token_sym = ID2SYM(rb_intern("NULL"));
		token_content = GraphQL_null_str;
		break;
		case IDENTIFIER:
		if (meta->reject_numbers_followed_by_names && meta->preceeded_by_number) {
			VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
			VALUE mCParser = rb_const_get_at(mGraphQL, rb_intern("CParser"));
			VALUE prev_token = rb_ary_entry(meta->tokens, -1);
			VALUE exception = rb_funcall(
			mCParser, rb_intern("prepare_number_name_parse_error"), 5,
			LONG2NUM(meta->line),
			LONG2NUM(meta->col),
			rb_str_new_cstr(meta->query_cstr),
			rb_ary_entry(prev_token, 3),
			rb_utf8_str_new(ts, te - ts)
			);
			rb_exc_raise(exception);
		}
		token_sym = ID2SYM(rb_intern("IDENTIFIER"));
		if (meta->dedup_identifiers) {
			token_content = rb_enc_interned_str(ts, te - ts, rb_utf8_encoding());
		} else {
			token_content = rb_utf8_str_new(ts, te - ts);
		}
		break;
		// Can't use these while we're in backwards-compat mode:
		// DYNAMIC_VALUE_TOKEN(INT)
		// DYNAMIC_VALUE_TOKEN(FLOAT)
		case INT_LITERAL:
		token_sym = ID2SYM(rb_intern("INT"));
		token_content = rb_utf8_str_new(ts, te - ts);
		this_token_is_number = 1;
		break;
		case FLOAT_LITERAL:
		token_sym = ID2SYM(rb_intern("FLOAT"));
		token_content = rb_utf8_str_new(ts, te - ts);
		this_token_is_number = 1;
		break;
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
		for (char *c = ts; c < te; c++) {
			if (*c == '\r' || *c == '\n') {
				if (*c == '\r' && c + 1 < te && c[1] == '\n') {
					c++;
				}
				line_incr++;
				next_col = te - c;
			}
		}
		break;
		// These are used only by the parser, this is never reached
		case STRING:
		case BAD_UNICODE_ESCAPE:
		break;
	}
	
	if (this_token_is_number && te < meta->pe && (*te == '.' || (*te >= '0' && *te <= '9'))) {
		VALUE mGraphQL = rb_const_get_at(rb_cObject, rb_intern("GraphQL"));
		VALUE cParseError = rb_const_get_at(mGraphQL, rb_intern("ParseError"));
		VALUE exception = rb_funcall(
		cParseError, rb_intern("new"), 4,
		rb_sprintf("Invalid number: unexpected character \"%c\"", *te),
		LONG2NUM(meta->line),
		LONG2NUM(meta->col),
		rb_str_new_cstr(meta->query_cstr)
		);
		rb_exc_raise(exception);
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
				tt = STRING;
			} else {
				tt = STRING;
				if (
					RB_TEST(rb_funcall(token_content, rb_intern("valid_encoding?"), 0)) &&
				RB_TEST(rb_funcall(token_content, rb_intern("match?"), 1, valid_string_pattern))
				) {
					rb_funcall(mGraphQLLanguageLexer, rb_intern("replace_escaped_characters_in_place"), 1, token_content);
					if (!RB_TEST(rb_funcall(token_content, rb_intern("valid_encoding?"), 0))) {
						token_sym = ID2SYM(rb_intern("BAD_UNICODE_ESCAPE"));
						tt = BAD_UNICODE_ESCAPE;
					}
				} else {
					token_sym = ID2SYM(rb_intern("BAD_UNICODE_ESCAPE"));
					tt = BAD_UNICODE_ESCAPE;
				}
			}
		}
		
		VALUE token = rb_ary_new_from_args(5,
		token_sym,
		rb_int2inum(meta->line),
		rb_int2inum(meta->col),
		token_content,
		INT2FIX(200 + (int)tt)
		);
		
		if (tt != COMMENT) {
			rb_ary_push(meta->tokens, token);
		}
		meta->preceeded_by_number = this_token_is_number;
	}
	// Update the position for the next token
	meta->col = next_col;
	meta->line += line_incr;
}

VALUE tokenize(VALUE query_rbstr, int fstring_identifiers, int reject_numbers_followed_by_names, int max_tokens) {
	int cs = 0;
	int act = 0;
	char *p = StringValuePtr(query_rbstr);
	long query_len = RSTRING_LEN(query_rbstr);
	char *pe = p + query_len;
	char *eof = pe;
	char *ts = 0;
	char *te = 0;
	VALUE tokens = rb_ary_new();
	struct Meta meta_s = {1, 1, p, pe, tokens, fstring_identifiers, reject_numbers_followed_by_names, 0, max_tokens, 0};
	Meta *meta = &meta_s;
	
	
#line 1015 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		cs = (int)graphql_c_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
	}
	
#line 442 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
#line 1026 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		unsigned int _trans = 0;
		const char * _keys;
		const short * _inds;
		int _ic;
		_resume: {}
		if ( p == pe && p != eof )
			goto _out;
		switch ( _graphql_c_lexer_from_state_actions[cs] ) {
			case 10:  {
				{
#line 1 "NONE"
					{ts = p;}}
				
#line 1041 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
				
				
				break; 
			}
		}
		
		if ( p == eof ) {
			if ( _graphql_c_lexer_eof_trans[cs] > 0 ) {
				_trans = (unsigned int)_graphql_c_lexer_eof_trans[cs] - 1;
			}
		}
		else {
			_keys = ( _graphql_c_lexer_trans_keys + ((cs<<1)));
			_inds = ( _graphql_c_lexer_indices + (_graphql_c_lexer_index_offsets[cs]));
			
			if ( ( (*( p))) <= 125 && ( (*( p))) >= -69 ) {
				_ic = (int)_graphql_c_lexer_char_class[(int)( (*( p))) - -69];
				if ( _ic <= (int)(*( _keys+1)) && _ic >= (int)(*( _keys)) )
					_trans = (unsigned int)(*( _inds + (int)( _ic - (int)(*( _keys)) ) )); 
				else
					_trans = (unsigned int)_graphql_c_lexer_index_defaults[cs];
			}
			else {
				_trans = (unsigned int)_graphql_c_lexer_index_defaults[cs];
			}
			
		}
		cs = (int)_graphql_c_lexer_cond_targs[_trans];
		
		if ( _graphql_c_lexer_cond_actions[_trans] != 0 ) {
			
			switch ( _graphql_c_lexer_cond_actions[_trans] ) {
				case 12:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1079 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 28:  {
					{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RCURLY, ts, te, meta); }
						}}
					
#line 1092 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 26:  {
					{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LCURLY, ts, te, meta); }
						}}
					
#line 1105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 18:  {
					{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RPAREN, ts, te, meta); }
						}}
					
#line 1118 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 17:  {
					{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LPAREN, ts, te, meta); }
						}}
					
#line 1131 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 25:  {
					{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RBRACKET, ts, te, meta); }
						}}
					
#line 1144 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 24:  {
					{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LBRACKET, ts, te, meta); }
						}}
					
#line 1157 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 20:  {
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COLON, ts, te, meta); }
						}}
					
#line 1170 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 34:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1183 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 3:  {
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1196 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 15:  {
					{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(VAR_SIGN, ts, te, meta); }
						}}
					
#line 1209 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 22:  {
					{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(DIR_SIGN, ts, te, meta); }
						}}
					
#line 1222 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 8:  {
					{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(ELLIPSIS, ts, te, meta); }
						}}
					
#line 1235 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 21:  {
					{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(EQUALS, ts, te, meta); }
						}}
					
#line 1248 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 14:  {
					{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BANG, ts, te, meta); }
						}}
					
#line 1261 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 27:  {
					{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(PIPE, ts, te, meta); }
						}}
					
#line 1274 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 16:  {
					{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(AMP, ts, te, meta); }
						}}
					
#line 1287 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 13:  {
					{
#line 95 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 95 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->line += 1;
								meta->col = 1;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1304 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 2:  {
					{
#line 106 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 106 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->col += te - ts;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1320 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"

					
					break; 
				}
				case 11:  {
					{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1333 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 36:  {
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT_LITERAL, ts, te, meta); }
						}}
					
#line 1346 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 37:  {
					{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(FLOAT_LITERAL, ts, te, meta); }
						}}
					
#line 1359 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 33:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1372 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 32:  {
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1385 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 38:  {
					{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(IDENTIFIER, ts, te, meta); }
						}}
					
#line 1398 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 35:  {
					{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COMMENT, ts, te, meta); }
						}}
					
#line 1411 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 30:  {
					{
#line 101 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 101 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->col += te - ts;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1427 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 29:  {
					{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1440 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 6:  {
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT_LITERAL, ts, te, meta); }
						}}
					
#line 1454 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 1:  {
					{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1468 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 4:  {
					{
#line 1 "NONE"
						{switch( act ) {
								case 1:  {
									p = ((te))-1;
									{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(INT_LITERAL, ts, te, meta); }
									break; 
								}
								case 2:  {
									p = ((te))-1;
									{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(FLOAT_LITERAL, ts, te, meta); }
									break; 
								}
								case 3:  {
									p = ((te))-1;
									{
#line 58 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(ON, ts, te, meta); }
									break; 
								}
								case 4:  {
									p = ((te))-1;
									{
#line 59 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(FRAGMENT, ts, te, meta); }
									break; 
								}
								case 5:  {
									p = ((te))-1;
									{
#line 60 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(TRUE_LITERAL, ts, te, meta); }
									break; 
								}
								case 6:  {
									p = ((te))-1;
									{
#line 61 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(FALSE_LITERAL, ts, te, meta); }
									break; 
								}
								case 7:  {
									p = ((te))-1;
									{
#line 62 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(NULL_LITERAL, ts, te, meta); }
									break; 
								}
								case 8:  {
									p = ((te))-1;
									{
#line 63 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(QUERY, ts, te, meta); }
									break; 
								}
								case 9:  {
									p = ((te))-1;
									{
#line 64 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(MUTATION, ts, te, meta); }
									break; 
								}
								case 10:  {
									p = ((te))-1;
									{
#line 65 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(SUBSCRIPTION, ts, te, meta); }
									break; 
								}
								case 11:  {
									p = ((te))-1;
									{
#line 66 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(SCHEMA, ts, te, meta); }
									break; 
								}
								case 12:  {
									p = ((te))-1;
									{
#line 67 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(SCALAR, ts, te, meta); }
									break; 
								}
								case 13:  {
									p = ((te))-1;
									{
#line 68 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(TYPE_LITERAL, ts, te, meta); }
									break; 
								}
								case 14:  {
									p = ((te))-1;
									{
#line 69 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(EXTEND, ts, te, meta); }
									break; 
								}
								case 15:  {
									p = ((te))-1;
									{
#line 70 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(IMPLEMENTS, ts, te, meta); }
									break; 
								}
								case 16:  {
									p = ((te))-1;
									{
#line 71 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(INTERFACE_LITERAL, ts, te, meta); }
									break; 
								}
								case 17:  {
									p = ((te))-1;
									{
#line 72 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(UNION, ts, te, meta); }
									break; 
								}
								case 18:  {
									p = ((te))-1;
									{
#line 73 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(ENUM, ts, te, meta); }
									break; 
								}
								case 19:  {
									p = ((te))-1;
									{
#line 74 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(INPUT_LITERAL, ts, te, meta); }
									break; 
								}
								case 20:  {
									p = ((te))-1;
									{
#line 75 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(DIRECTIVE, ts, te, meta); }
									break; 
								}
								case 21:  {
									p = ((te))-1;
									{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(REPEATABLE, ts, te, meta); }
									break; 
								}
								case 29:  {
									p = ((te))-1;
									{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(BLOCK_STRING, ts, te, meta); }
									break; 
								}
								case 30:  {
									p = ((te))-1;
									{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(QUOTED_STRING, ts, te, meta); }
									break; 
								}
								case 38:  {
									p = ((te))-1;
									{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(IDENTIFIER, ts, te, meta); }
									break; 
								}
							}}
					}
					
#line 1648 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 19:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1658 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 1;}}
					
#line 1664 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 7:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1674 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 2;}}
					
#line 1680 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 49:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1690 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 58 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 3;}}
					
#line 1696 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 43:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1706 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 59 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 4;}}
					
#line 1712 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 55:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1722 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 60 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 5;}}
					
#line 1728 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 42:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1738 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 61 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 6;}}
					
#line 1744 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 48:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1754 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 62 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 7;}}
					
#line 1760 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 50:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1770 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 63 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 8;}}
					
#line 1776 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 47:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1786 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 64 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 9;}}
					
#line 1792 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 54:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1802 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 65 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 10;}}
					
#line 1808 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 53:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1818 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 66 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 11;}}
					
#line 1824 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 52:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1834 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 67 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 12;}}
					
#line 1840 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 56:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1850 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 68 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 13;}}
					
#line 1856 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 41:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1866 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 69 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 14;}}
					
#line 1872 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 44:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1882 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 70 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 15;}}
					
#line 1888 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 46:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1898 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 71 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 16;}}
					
#line 1904 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 57:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1914 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 72 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 17;}}
					
#line 1920 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 40:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1930 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 73 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 18;}}
					
#line 1936 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 45:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1946 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 74 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 19;}}
					
#line 1952 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 39:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1962 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 75 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 20;}}
					
#line 1968 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 51:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1978 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 21;}}
					
#line 1984 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 5:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1994 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 29;}}
					
#line 2000 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 31:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2010 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 30;}}
					
#line 2016 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 23:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2026 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 38;}}
					
#line 2032 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"


					break;
				}
			}
			
		}
		
		if ( p == eof ) {
			if ( cs >= 19 )
				goto _out;
		}
		else {
			switch ( _graphql_c_lexer_to_state_actions[cs] ) {
				case 9:  {
					{
#line 1 "NONE"
						{ts = 0;}}
					
#line 2052 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
			}
			
			p += 1;
			goto _resume;
		}
		_out: {}
	}
	
#line 443 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
	return tokens;
}


#define SETUP_STATIC_TOKEN_VARIABLE(token_name, token_content) \
GraphQLTokenString##token_name = rb_utf8_str_new_cstr(token_content); \
rb_funcall(GraphQLTokenString##token_name, rb_intern("-@"), 0); \
rb_global_variable(&GraphQLTokenString##token_name); \

#define SETUP_STATIC_STRING(var_name, str_content) \
var_name = rb_utf8_str_new_cstr(str_content); \
rb_global_variable(&var_name); \
rb_str_freeze(var_name); \

void setup_static_token_variables(void) {
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
	SETUP_STATIC_TOKEN_VARIABLE(EXTEND, "extend")
	SETUP_STATIC_TOKEN_VARIABLE(IMPLEMENTS, "implements")
	SETUP_STATIC_TOKEN_VARIABLE(INTERFACE, "interface")
	SETUP_STATIC_TOKEN_VARIABLE(UNION, "union")
	SETUP_STATIC_TOKEN_VARIABLE(ENUM, "enum")
	SETUP_STATIC_TOKEN_VARIABLE(DIRECTIVE, "directive")
	SETUP_STATIC_TOKEN_VARIABLE(INPUT, "input")
	
	SETUP_STATIC_STRING(GraphQL_type_str, "type")
	SETUP_STATIC_STRING(GraphQL_true_str, "true")
	SETUP_STATIC_STRING(GraphQL_false_str, "false")
	SETUP_STATIC_STRING(GraphQL_null_str, "null")
}
