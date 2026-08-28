#line 1 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

#line 107 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"



#line 8 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
static const char _graphql_c_lexer_trans_keys[] = {
	1, 22, 4, 43, 14, 47, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 49,
	4, 22, 4, 4, 4, 4, 4, 22,
	4, 4, 4, 4, 14, 15, 10, 15,
	14, 15, 12, 12, 0, 49, 0, 0,
	1, 22, 4, 4, 4, 4, 4, 4,
	4, 22, 4, 4, 4, 4, 1, 1,
	14, 15, 12, 29, 14, 29, 14, 15,
	12, 29, 12, 12, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 0
};

static const signed char _graphql_c_lexer_char_class[] = {
	0, 1, 2, 2, 1, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 0,
	3, 4, 5, 6, 2, 7, 2, 8,
	9, 2, 10, 0, 11, 12, 13, 14,
	15, 15, 15, 15, 15, 15, 15, 15,
	15, 16, 2, 2, 17, 2, 2, 18,
	19, 19, 19, 19, 20, 19, 19, 19,
	19, 19, 19, 19, 19, 19, 19, 19,
	19, 19, 19, 19, 19, 19, 19, 19,
	19, 19, 21, 22, 23, 2, 24, 2,
	25, 26, 27, 28, 29, 30, 31, 32,
	33, 19, 19, 34, 35, 36, 37, 38,
	39, 40, 41, 42, 43, 44, 19, 45,
	46, 19, 47, 48, 49, 0
};

static const short _graphql_c_lexer_index_offsets[] = {
	0, 22, 62, 96, 129, 162, 195, 228,
	264, 283, 284, 285, 304, 305, 306, 308,
	314, 316, 317, 367, 368, 390, 391, 392,
	393, 412, 413, 414, 415, 417, 435, 451,
	453, 471, 472, 505, 538, 571, 604, 637,
	670, 703, 736, 769, 802, 835, 868, 901,
	934, 967, 1000, 1033, 1066, 1099, 1132, 1165,
	1198, 1231, 1264, 1297, 1330, 1363, 1396, 1429,
	1462, 1495, 1528, 1561, 1594, 1627, 1660, 1693,
	1726, 1759, 1792, 1825, 1858, 1891, 1924, 1957,
	1990, 2023, 2056, 2089, 2122, 2155, 2188, 2221,
	2254, 2287, 2320, 2353, 2386, 2419, 2452, 2485,
	2518, 2551, 2584, 2617, 2650, 2683, 2716, 2749,
	2782, 2815, 2848, 2881, 2914, 2947, 2980, 3013,
	3046, 3079, 3112, 3145, 3178, 3211, 3244, 3277,
	3310, 3343, 3376, 3409, 3442, 3475, 3508, 3541,
	3574, 0
};

static const short _graphql_c_lexer_indices[] = {
	0, 1, 1, 2, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 3, 1, 0,
	0, 0, 0, 0, 0, 0, 0, 1,
	0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 0, 1, 0, 0, 0,
	1, 0, 0, 0, 0, 0, 1, 0,
	0, 0, 1, 0, 1, 4, 5, 5,
	0, 0, 0, 5, 5, 0, 0, 0,
	0, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 6,
	7, 7, 0, 0, 0, 7, 7, 0,
	0, 0, 0, 7, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7,
	7, 8, 8, 0, 0, 0, 8, 8,
	0, 0, 0, 0, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 1, 1, 0, 0, 0, 1,
	1, 0, 0, 0, 0, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 9, 9, 0, 0, 0,
	9, 9, 0, 0, 0, 0, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 0, 0,
	0, 9, 9, 0, 0, 0, 0, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 0, 0, 1,
	12, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 13, 14, 15, 16, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 13,
	17, 18, 20, 20, 21, 21, 10, 10,
	22, 22, 22, 22, 23, 26, 27, 25,
	28, 29, 30, 31, 32, 33, 34, 25,
	35, 36, 25, 37, 38, 39, 40, 41,
	42, 42, 43, 25, 44, 42, 42, 42,
	42, 45, 46, 47, 42, 42, 48, 42,
	49, 50, 51, 42, 52, 53, 54, 55,
	56, 42, 42, 42, 57, 58, 59, 26,
	61, 1, 1, 62, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 3, 11, 65,
	66, 67, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 13, 68, 15, 69, 37,
	38, 71, 70, 70, 70, 70, 70, 70,
	70, 72, 70, 70, 70, 70, 70, 70,
	70, 70, 72, 20, 20, 73, 73, 73,
	73, 72, 73, 73, 73, 73, 73, 73,
	73, 73, 72, 22, 22, 71, 70, 38,
	38, 70, 70, 70, 70, 72, 70, 70,
	70, 70, 70, 70, 70, 70, 72, 74,
	42, 42, 10, 10, 10, 42, 42, 10,
	10, 10, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 76, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 77, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 78, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 79, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 80, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 81, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 82, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 83,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 84,
	42, 42, 42, 42, 42, 42, 42, 42,
	85, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 86,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	87, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	88, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 89, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 90, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 91, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 92, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 93, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 94, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 95, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 96, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 97,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 98, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 99, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 100, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 101, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 102, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 103,
	104, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 105, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	106, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 107, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 108, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 109, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 110, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 111, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 112, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 113, 42, 42, 42, 114,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 115, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 116, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 117, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 118, 42, 42, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 42,
	119, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 120, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 121,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 122, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 123, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 124, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 125, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 126, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 127, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	128, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	129, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	130, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	131, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 132, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 133, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 134, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 135,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 136, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 137, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 138, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 139, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 140, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 141, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 142, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 143, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 144, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 145, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 146, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 147, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 148, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	149, 42, 42, 42, 42, 42, 42, 150,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 151, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 152, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 153, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	154, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 155,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 156, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	157, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	158, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 159, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 160, 42, 42, 42, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 161, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 162, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 163, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 164, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 165, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 166, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	167, 42, 42, 42, 42, 42, 168, 42,
	42, 75, 75, 75, 42, 42, 75, 75,
	75, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 169, 42, 42, 42,
	42, 42, 75, 75, 75, 42, 42, 75,
	75, 75, 42, 42, 42, 42, 42, 170,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 75, 75, 75, 42, 42,
	75, 75, 75, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 171, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 75, 75, 75, 42,
	42, 75, 75, 75, 42, 42, 42, 42,
	42, 172, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 75, 75, 75,
	42, 42, 75, 75, 75, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 173, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 75, 75,
	75, 42, 42, 75, 75, 75, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 174,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 75,
	75, 75, 42, 42, 75, 75, 75, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 175, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 42,
	75, 75, 75, 42, 42, 75, 75, 75,
	42, 42, 42, 42, 42, 42, 42, 42,
	42, 42, 42, 42, 176, 42, 42, 42,
	42, 42, 42, 42, 42, 42, 42, 0
};

static const signed char _graphql_c_lexer_index_defaults[] = {
	1, 0, 0, 0, 0, 0, 0, 0,
	11, 11, 11, 11, 11, 11, 19, 10,
	10, 0, 25, 60, 1, 63, 64, 64,
	11, 11, 11, 30, 61, 70, 73, 73,
	70, 61, 10, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 75, 75, 75, 75, 75, 75, 75,
	75, 0
};

static const short _graphql_c_lexer_cond_targs[] = {
	18, 0, 18, 1, 2, 3, 6, 4,
	5, 7, 18, 8, 9, 11, 10, 22,
	12, 13, 24, 18, 30, 16, 31, 18,
	18, 18, 19, 18, 18, 20, 27, 18,
	18, 18, 18, 28, 33, 29, 32, 18,
	18, 18, 34, 18, 18, 35, 43, 50,
	60, 78, 85, 88, 89, 93, 102, 120,
	125, 18, 18, 18, 18, 18, 21, 18,
	18, 23, 18, 25, 26, 18, 18, 14,
	15, 18, 17, 18, 36, 37, 38, 39,
	40, 41, 42, 34, 44, 46, 45, 34,
	47, 48, 49, 34, 51, 54, 52, 53,
	34, 55, 56, 57, 58, 59, 34, 61,
	69, 62, 63, 64, 65, 66, 67, 68,
	34, 70, 72, 71, 34, 73, 74, 75,
	76, 77, 34, 79, 80, 81, 82, 83,
	84, 34, 86, 87, 34, 34, 90, 91,
	92, 34, 94, 95, 96, 97, 98, 99,
	100, 101, 34, 103, 110, 104, 107, 105,
	106, 34, 108, 109, 34, 111, 112, 113,
	114, 115, 116, 117, 118, 119, 34, 121,
	123, 122, 34, 124, 34, 126, 127, 128,
	34, 0
};

static const signed char _graphql_c_lexer_cond_actions[] = {
	1, 0, 2, 0, 0, 0, 0, 0,
	0, 0, 3, 0, 0, 0, 0, 0,
	0, 0, 4, 5, 6, 0, 0, 7,
	0, 10, 0, 11, 12, 13, 0, 14,
	15, 16, 17, 0, 13, 18, 18, 19,
	20, 21, 22, 23, 24, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 25, 26, 27, 28, 29, 30, 31,
	32, 0, 33, 4, 4, 34, 35, 0,
	0, 36, 0, 37, 0, 0, 0, 0,
	0, 0, 0, 38, 0, 0, 0, 39,
	0, 0, 0, 40, 0, 0, 0, 0,
	41, 0, 0, 0, 0, 0, 42, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	43, 0, 0, 0, 44, 0, 0, 0,
	0, 0, 45, 0, 0, 0, 0, 0,
	0, 46, 0, 0, 47, 48, 0, 0,
	0, 49, 0, 0, 0, 0, 0, 0,
	0, 0, 50, 0, 0, 0, 0, 0,
	0, 51, 0, 0, 52, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 53, 0,
	0, 0, 54, 0, 55, 0, 0, 0,
	56, 0
};

static const signed char _graphql_c_lexer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 8, 0, 0, 0, 0, 0,
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
	0, 0
};

static const signed char _graphql_c_lexer_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 9, 0, 0, 0, 0, 0,
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
	0, 0
};

static const signed char _graphql_c_lexer_eof_trans[] = {
	1, 1, 1, 1, 1, 1, 1, 1,
	11, 11, 11, 11, 11, 11, 20, 11,
	11, 1, 25, 61, 62, 64, 65, 65,
	65, 65, 65, 70, 62, 71, 74, 74,
	71, 62, 11, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 76, 76, 76, 76, 76, 76, 76,
	76, 0
};

static const int graphql_c_lexer_start = 18;
static const int graphql_c_lexer_first_final = 18;
static const int graphql_c_lexer_error = -1;

static const int graphql_c_lexer_en_main = 18;


#line 109 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"


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
typedef enum TokenType {
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
	FLOAT,
	FRAGMENT,
	IDENTIFIER,
	INPUT,
	IMPLEMENTS,
	INT,
	INTERFACE,
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
} TokenType;

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

void emit(TokenType tt, char *ts, char *te, Meta *meta) {
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
		STATIC_VALUE_TOKEN(INTERFACE, "interface")
		STATIC_VALUE_TOKEN(UNION, "union")
		STATIC_VALUE_TOKEN(ENUM, "enum")
		STATIC_VALUE_TOKEN(DIRECTIVE, "directive")
		STATIC_VALUE_TOKEN(INPUT, "input")
		// For these, the enum name doesn't match the symbol name:
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
		case INT:
		token_sym = ID2SYM(rb_intern("INT"));
		token_content = rb_utf8_str_new(ts, te - ts);
		this_token_is_number = 1;
		break;
		case FLOAT:
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
		line_incr = FIX2INT(rb_funcall(token_content, rb_intern("count"), 1, rb_utf8_str_new_cstr("\n")));
		break;
		// These are used only by the parser, this is never reached
		case STRING:
		case BAD_UNICODE_ESCAPE:
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
	// Bump the column counter for the next token
	meta->col += te - ts;
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
	
	
#line 977 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		cs = (int)graphql_c_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
	}
	
#line 408 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
#line 988 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		unsigned int _trans = 0;
		const char * _keys;
		const short * _inds;
		int _ic;
		_resume: {}
		if ( p == pe && p != eof )
			goto _out;
		switch ( _graphql_c_lexer_from_state_actions[cs] ) {
			case 9:  {
				{
#line 1 "NONE"
					{ts = p;}}
				
#line 1003 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
				
				
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
			
			if ( ( (*( p))) <= 125 && ( (*( p))) >= 9 ) {
				_ic = (int)_graphql_c_lexer_char_class[(int)( (*( p))) - 9];
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
				case 13:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1041 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 27:  {
					{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RCURLY, ts, te, meta); }
						}}
					
#line 1054 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 25:  {
					{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LCURLY, ts, te, meta); }
						}}
					
#line 1067 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 17:  {
					{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RPAREN, ts, te, meta); }
						}}
					
#line 1080 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 16:  {
					{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LPAREN, ts, te, meta); }
						}}
					
#line 1093 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 24:  {
					{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RBRACKET, ts, te, meta); }
						}}
					
#line 1106 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 23:  {
					{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LBRACKET, ts, te, meta); }
						}}
					
#line 1119 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 19:  {
					{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COLON, ts, te, meta); }
						}}
					
#line 1132 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 33:  {
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1145 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 2:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1158 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 14:  {
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(VAR_SIGN, ts, te, meta); }
						}}
					
#line 1171 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 21:  {
					{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(DIR_SIGN, ts, te, meta); }
						}}
					
#line 1184 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 7:  {
					{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(ELLIPSIS, ts, te, meta); }
						}}
					
#line 1197 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 20:  {
					{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(EQUALS, ts, te, meta); }
						}}
					
#line 1210 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 12:  {
					{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BANG, ts, te, meta); }
						}}
					
#line 1223 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 26:  {
					{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(PIPE, ts, te, meta); }
						}}
					
#line 1236 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 15:  {
					{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(AMP, ts, te, meta); }
						}}
					
#line 1249 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 11:  {
					{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->line += 1;
								meta->col = 1;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1266 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 10:  {
					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1279 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 35:  {
					{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT, ts, te, meta); }
						}}
					
#line 1292 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 36:  {
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(FLOAT, ts, te, meta); }
						}}
					
#line 1305 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 32:  {
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1318 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 31:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1331 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 37:  {
					{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(IDENTIFIER, ts, te, meta); }
						}}
					
#line 1344 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 34:  {
					{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COMMENT, ts, te, meta); }
						}}
					
#line 1357 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 28:  {
					{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->col += te - ts;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1373 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 29:  {
					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1386 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 5:  {
					{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT, ts, te, meta); }
						}}
					
#line 1400 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 1:  {
					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1414 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 3:  {
					{
#line 1 "NONE"
						{switch( act ) {
								case 1:  {
									p = ((te))-1;
									{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(INT, ts, te, meta); }
									break; 
								}
								case 2:  {
									p = ((te))-1;
									{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(FLOAT, ts, te, meta); }
									break; 
								}
								case 3:  {
									p = ((te))-1;
									{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(ON, ts, te, meta); }
									break; 
								}
								case 4:  {
									p = ((te))-1;
									{
#line 58 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(FRAGMENT, ts, te, meta); }
									break; 
								}
								case 5:  {
									p = ((te))-1;
									{
#line 59 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(TRUE_LITERAL, ts, te, meta); }
									break; 
								}
								case 6:  {
									p = ((te))-1;
									{
#line 60 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(FALSE_LITERAL, ts, te, meta); }
									break; 
								}
								case 7:  {
									p = ((te))-1;
									{
#line 61 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(NULL_LITERAL, ts, te, meta); }
									break; 
								}
								case 8:  {
									p = ((te))-1;
									{
#line 62 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(QUERY, ts, te, meta); }
									break; 
								}
								case 9:  {
									p = ((te))-1;
									{
#line 63 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(MUTATION, ts, te, meta); }
									break; 
								}
								case 10:  {
									p = ((te))-1;
									{
#line 64 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(SUBSCRIPTION, ts, te, meta); }
									break; 
								}
								case 11:  {
									p = ((te))-1;
									{
#line 65 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(SCHEMA, ts, te, meta); }
									break; 
								}
								case 12:  {
									p = ((te))-1;
									{
#line 66 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(SCALAR, ts, te, meta); }
									break; 
								}
								case 13:  {
									p = ((te))-1;
									{
#line 67 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(TYPE_LITERAL, ts, te, meta); }
									break; 
								}
								case 14:  {
									p = ((te))-1;
									{
#line 68 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(EXTEND, ts, te, meta); }
									break; 
								}
								case 15:  {
									p = ((te))-1;
									{
#line 69 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(IMPLEMENTS, ts, te, meta); }
									break; 
								}
								case 16:  {
									p = ((te))-1;
									{
#line 70 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(INTERFACE, ts, te, meta); }
									break; 
								}
								case 17:  {
									p = ((te))-1;
									{
#line 71 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(UNION, ts, te, meta); }
									break; 
								}
								case 18:  {
									p = ((te))-1;
									{
#line 72 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(ENUM, ts, te, meta); }
									break; 
								}
								case 19:  {
									p = ((te))-1;
									{
#line 73 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(INPUT, ts, te, meta); }
									break; 
								}
								case 20:  {
									p = ((te))-1;
									{
#line 74 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(DIRECTIVE, ts, te, meta); }
									break; 
								}
								case 21:  {
									p = ((te))-1;
									{
#line 75 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(REPEATABLE, ts, te, meta); }
									break; 
								}
								case 29:  {
									p = ((te))-1;
									{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(BLOCK_STRING, ts, te, meta); }
									break; 
								}
								case 30:  {
									p = ((te))-1;
									{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(QUOTED_STRING, ts, te, meta); }
									break; 
								}
								case 38:  {
									p = ((te))-1;
									{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(IDENTIFIER, ts, te, meta); }
									break; 
								}
							}}
					}
					
#line 1594 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 18:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1604 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 1;}}
					
#line 1610 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 6:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1620 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 2;}}
					
#line 1626 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 48:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1636 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 3;}}
					
#line 1642 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 42:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1652 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 58 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 4;}}
					
#line 1658 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 54:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1668 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 59 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 5;}}
					
#line 1674 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 41:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1684 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 60 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 6;}}
					
#line 1690 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 47:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1700 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 61 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 7;}}
					
#line 1706 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 49:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1716 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 62 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 8;}}
					
#line 1722 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 46:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1732 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 63 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 9;}}
					
#line 1738 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 53:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1748 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 64 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 10;}}
					
#line 1754 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 52:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1764 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 65 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 11;}}
					
#line 1770 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 51:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1780 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 66 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 12;}}
					
#line 1786 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 55:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1796 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 67 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 13;}}
					
#line 1802 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 40:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1812 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 68 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 14;}}
					
#line 1818 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 43:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1828 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 69 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 15;}}
					
#line 1834 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 45:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1844 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 70 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 16;}}
					
#line 1850 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 56:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1860 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 71 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 17;}}
					
#line 1866 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 39:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1876 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 72 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 18;}}
					
#line 1882 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 44:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1892 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 73 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 19;}}
					
#line 1898 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 38:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1908 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 74 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 20;}}
					
#line 1914 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 50:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1924 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 75 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 21;}}
					
#line 1930 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 4:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1940 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 29;}}
					
#line 1946 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 30:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1956 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 30;}}
					
#line 1962 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 22:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1972 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 38;}}
					
#line 1978 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
			}
			
		}
		
		if ( p == eof ) {
			if ( cs >= 18 )
				goto _out;
		}
		else {
			switch ( _graphql_c_lexer_to_state_actions[cs] ) {
				case 8:  {
					{
#line 1 "NONE"
						{ts = 0;}}
					
#line 1998 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
			}
			
			p += 1;
			goto _resume;
		}
		_out: {}
	}
	
#line 409 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
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
