#line 1 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

#line 107 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"



#line 8 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
static const char _graphql_c_lexer_trans_keys[] = {
	2, 2, 0, 0, 5, 25, 7, 46,
	17, 50, 17, 49, 17, 49, 17, 49,
	17, 49, 17, 52, 7, 25, 7, 7,
	7, 7, 7, 25, 7, 7, 7, 7,
	17, 18, 13, 18, 17, 18, 15, 15,
	3, 52, 0, 0, 3, 4, 5, 25,
	7, 7, 7, 7, 7, 7, 7, 25,
	7, 7, 7, 7, 5, 5, 17, 18,
	15, 32, 17, 32, 17, 18, 15, 32,
	15, 15, 17, 49, 17, 49, 17, 49,
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
	0
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
	0, 1, 2, 23, 63, 97, 130, 163,
	196, 229, 265, 284, 285, 286, 305, 306,
	307, 309, 315, 317, 318, 368, 369, 371,
	392, 393, 394, 395, 414, 415, 416, 417,
	419, 437, 453, 455, 473, 474, 507, 540,
	573, 606, 639, 672, 705, 738, 771, 804,
	837, 870, 903, 936, 969, 1002, 1035, 1068,
	1101, 1134, 1167, 1200, 1233, 1266, 1299, 1332,
	1365, 1398, 1431, 1464, 1497, 1530, 1563, 1596,
	1629, 1662, 1695, 1728, 1761, 1794, 1827, 1860,
	1893, 1926, 1959, 1992, 2025, 2058, 2091, 2124,
	2157, 2190, 2223, 2256, 2289, 2322, 2355, 2388,
	2421, 2454, 2487, 2520, 2553, 2586, 2619, 2652,
	2685, 2718, 2751, 2784, 2817, 2850, 2883, 2916,
	2949, 2982, 3015, 3048, 3081, 3114, 3147, 3180,
	3213, 3246, 3279, 3312, 3345, 3378, 3411, 3444,
	3477, 3510, 3543, 3576, 0
};

static const short _graphql_c_lexer_indices[] = {
	1, 3, 4, 5, 6, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 7, 5,
	4, 4, 4, 4, 4, 4, 4, 4,
	5, 4, 4, 4, 4, 4, 4, 4,
	4, 5, 4, 4, 4, 5, 4, 4,
	4, 5, 4, 4, 4, 4, 4, 5,
	4, 4, 4, 5, 4, 5, 8, 9,
	9, 4, 4, 4, 9, 9, 4, 4,
	4, 4, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	10, 11, 11, 4, 4, 4, 11, 11,
	4, 4, 4, 4, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 12, 12, 4, 4, 4, 12,
	12, 4, 4, 4, 4, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 5, 5, 4, 4, 4,
	5, 5, 4, 4, 4, 4, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 13, 13, 4, 4,
	4, 13, 13, 4, 4, 4, 4, 13,
	13, 13, 13, 13, 13, 13, 13, 13,
	13, 13, 13, 13, 13, 13, 13, 13,
	13, 13, 13, 13, 13, 13, 13, 4,
	4, 4, 13, 13, 4, 4, 4, 4,
	13, 13, 13, 13, 13, 13, 13, 13,
	13, 13, 13, 13, 13, 13, 13, 13,
	13, 13, 13, 13, 13, 13, 4, 4,
	5, 15, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 16, 17, 18, 19, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	16, 20, 21, 23, 23, 24, 24, 0,
	0, 25, 25, 25, 25, 26, 29, 1,
	30, 31, 32, 33, 34, 35, 36, 37,
	28, 38, 39, 28, 40, 41, 42, 43,
	44, 45, 45, 46, 28, 47, 45, 45,
	45, 45, 48, 49, 50, 45, 45, 51,
	45, 52, 53, 54, 45, 55, 56, 57,
	58, 59, 45, 45, 45, 60, 61, 62,
	3, 65, 1, 63, 5, 66, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 7,
	14, 69, 70, 71, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 16, 72, 18,
	73, 40, 41, 75, 74, 74, 74, 74,
	74, 74, 74, 76, 74, 74, 74, 74,
	74, 74, 74, 74, 76, 23, 23, 77,
	77, 77, 77, 76, 77, 77, 77, 77,
	77, 77, 77, 77, 76, 25, 25, 75,
	74, 41, 41, 74, 74, 74, 74, 76,
	74, 74, 74, 74, 74, 74, 74, 74,
	76, 78, 45, 45, 0, 0, 0, 45,
	45, 0, 0, 0, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 81, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 82, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 83, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 84, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 85, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 86,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 87, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 88, 45, 45, 45, 45, 45, 45,
	45, 45, 89, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 90, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 91, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 92, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 93, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 94, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 95,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 96, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 97, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 98,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 99,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 100, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 101, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	102, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 103, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	104, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	105, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 106,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 107, 108, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 109, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 110, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 111, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 112, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	113, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	114, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 115,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 116,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 117, 45, 45,
	45, 118, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 119, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 120, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 121,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 122, 45, 45, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 45, 123, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 124, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 125, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 126, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 127, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 128, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 129, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 130, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 131, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 132, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 133, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 134, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 135, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 136, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 137, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 138, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 139, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 140, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 141, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 142, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 143, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 144, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 145, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 146, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 147, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 148,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	149, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 150, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 151, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 152, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 153, 45, 45, 45, 45, 45,
	45, 154, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 155, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 156, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 157, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 158, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 159, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	160, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 161, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 162, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 163, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 164, 45, 45, 45, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 165, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 166, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	167, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	168, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 169, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 170, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 171, 45, 45, 45, 45, 45,
	172, 45, 45, 79, 79, 79, 45, 45,
	79, 79, 79, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 173, 45,
	45, 45, 45, 45, 79, 79, 79, 45,
	45, 79, 79, 79, 45, 45, 45, 45,
	45, 174, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 79, 79, 79,
	45, 45, 79, 79, 79, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 175, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 79, 79,
	79, 45, 45, 79, 79, 79, 45, 45,
	45, 45, 45, 176, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 79,
	79, 79, 45, 45, 79, 79, 79, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 177, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	79, 79, 79, 45, 45, 79, 79, 79,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 178, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 79, 79, 45, 45, 79, 79,
	79, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 179, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 79, 79, 79, 45, 45, 79,
	79, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 180, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 0
};

static const signed char _graphql_c_lexer_index_defaults[] = {
	0, 2, 5, 4, 4, 4, 4, 4,
	4, 4, 14, 14, 14, 14, 14, 14,
	22, 0, 0, 4, 28, 63, 64, 5,
	67, 68, 68, 14, 14, 14, 33, 63,
	74, 77, 77, 74, 63, 0, 79, 79,
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
	79, 79, 79, 79, 0
};

static const short _graphql_c_lexer_cond_targs[] = {
	20, 22, 20, 0, 20, 2, 20, 3,
	4, 5, 8, 6, 7, 9, 10, 11,
	13, 12, 25, 14, 15, 27, 20, 33,
	18, 34, 20, 20, 20, 21, 20, 20,
	23, 30, 20, 20, 20, 20, 31, 36,
	32, 35, 20, 20, 20, 37, 20, 20,
	38, 46, 53, 63, 81, 88, 91, 92,
	96, 105, 123, 128, 20, 20, 20, 20,
	20, 1, 24, 20, 20, 26, 20, 28,
	29, 20, 20, 16, 17, 20, 19, 20,
	39, 40, 41, 42, 43, 44, 45, 37,
	47, 49, 48, 37, 50, 51, 52, 37,
	54, 57, 55, 56, 37, 58, 59, 60,
	61, 62, 37, 64, 72, 65, 66, 67,
	68, 69, 70, 71, 37, 73, 75, 74,
	37, 76, 77, 78, 79, 80, 37, 82,
	83, 84, 85, 86, 87, 37, 89, 90,
	37, 37, 93, 94, 95, 37, 97, 98,
	99, 100, 101, 102, 103, 104, 37, 106,
	113, 107, 110, 108, 109, 37, 111, 112,
	37, 114, 115, 116, 117, 118, 119, 120,
	121, 122, 37, 124, 126, 125, 37, 127,
	37, 129, 130, 131, 37, 0
};

static const signed char _graphql_c_lexer_cond_actions[] = {
	1, 2, 3, 0, 4, 0, 5, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 6, 7, 8,
	0, 0, 9, 0, 12, 13, 14, 15,
	16, 0, 17, 18, 19, 20, 0, 16,
	21, 21, 22, 23, 24, 25, 26, 27,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 28, 29, 30, 31,
	32, 0, 33, 34, 35, 0, 36, 6,
	6, 37, 38, 0, 0, 39, 0, 40,
	0, 0, 0, 0, 0, 0, 0, 41,
	0, 0, 0, 42, 0, 0, 0, 43,
	0, 0, 0, 0, 44, 0, 0, 0,
	0, 0, 45, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 46, 0, 0, 0,
	47, 0, 0, 0, 0, 0, 48, 0,
	0, 0, 0, 0, 0, 49, 0, 0,
	50, 51, 0, 0, 0, 52, 0, 0,
	0, 0, 0, 0, 0, 0, 53, 0,
	0, 0, 0, 0, 0, 54, 0, 0,
	55, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 56, 0, 0, 0, 57, 0,
	58, 0, 0, 0, 59, 0
};

static const signed char _graphql_c_lexer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 10, 0, 0, 0,
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
	0, 0, 0, 0, 0
};

static const signed char _graphql_c_lexer_from_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 11, 0, 0, 0,
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
	0, 0, 0, 0, 0
};

static const signed char _graphql_c_lexer_eof_trans[] = {
	1, 3, 5, 5, 5, 5, 5, 5,
	5, 5, 1, 1, 1, 1, 1, 1,
	23, 1, 1, 5, 28, 64, 65, 64,
	68, 69, 69, 69, 69, 69, 74, 64,
	75, 78, 78, 75, 64, 1, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 80, 80, 80, 80,
	80, 80, 80, 80, 0
};

static const int graphql_c_lexer_start = 20;
static const int graphql_c_lexer_first_final = 20;
static const int graphql_c_lexer_error = -1;

static const int graphql_c_lexer_en_main = 20;


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
	
	
#line 989 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		cs = (int)graphql_c_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
	}
	
#line 408 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
#line 1000 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		unsigned int _trans = 0;
		const char * _keys;
		const short * _inds;
		int _ic;
		_resume: {}
		if ( p == pe && p != eof )
			goto _out;
		switch ( _graphql_c_lexer_from_state_actions[cs] ) {
			case 11:  {
				{
#line 1 "NONE"
					{ts = p;}}
				
#line 1015 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
				
				
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
				case 16:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1053 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 30:  {
					{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RCURLY, ts, te, meta); }
						}}
					
#line 1066 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 28:  {
					{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LCURLY, ts, te, meta); }
						}}
					
#line 1079 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 20:  {
					{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RPAREN, ts, te, meta); }
						}}
					
#line 1092 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 19:  {
					{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LPAREN, ts, te, meta); }
						}}
					
#line 1105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 27:  {
					{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RBRACKET, ts, te, meta); }
						}}
					
#line 1118 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 26:  {
					{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LBRACKET, ts, te, meta); }
						}}
					
#line 1131 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 22:  {
					{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COLON, ts, te, meta); }
						}}
					
#line 1144 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 36:  {
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1157 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 5:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1170 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 17:  {
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(VAR_SIGN, ts, te, meta); }
						}}
					
#line 1183 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 24:  {
					{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(DIR_SIGN, ts, te, meta); }
						}}
					
#line 1196 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 9:  {
					{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(ELLIPSIS, ts, te, meta); }
						}}
					
#line 1209 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 23:  {
					{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(EQUALS, ts, te, meta); }
						}}
					
#line 1222 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 15:  {
					{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BANG, ts, te, meta); }
						}}
					
#line 1235 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 29:  {
					{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(PIPE, ts, te, meta); }
						}}
					
#line 1248 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 18:  {
					{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(AMP, ts, te, meta); }
						}}
					
#line 1261 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 14:  {
					{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->line += 1;
								meta->col = 1;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1278 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 12:  {
					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1291 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 38:  {
					{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT, ts, te, meta); }
						}}
					
#line 1304 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 39:  {
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(FLOAT, ts, te, meta); }
						}}
					
#line 1317 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 35:  {
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1330 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 34:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1343 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 40:  {
					{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(IDENTIFIER, ts, te, meta); }
						}}
					
#line 1356 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 37:  {
					{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COMMENT, ts, te, meta); }
						}}
					
#line 1369 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 32:  {
					{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								
								meta->col += te - ts;
								meta->preceeded_by_number = 0;
							}
						}}
					
#line 1385 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 31:  {
					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1398 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 7:  {
					{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT, ts, te, meta); }
						}}
					
#line 1412 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 3:  {
					{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

								meta->col += te - ts;
								meta->preceeded_by_number = 0;
							}
						}}

#line 1429 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"


					break;
				}
				case 4:  {
					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1443 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 1:  {
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
								case 41:  {
									p = ((te))-1;
									{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

										meta->col += te - ts;
										meta->preceeded_by_number = 0;
									}
									break;
								}
								case 42:  {
									p = ((te))-1;
									{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
										emit(UNKNOWN_CHAR, ts, te, meta); }
									break;
								}
							}}
					}
					
#line 1640 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 21:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1650 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 55 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 1;}}
					
#line 1656 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 8:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1666 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 2;}}
					
#line 1672 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 51:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1682 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 3;}}
					
#line 1688 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 45:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1698 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 58 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 4;}}
					
#line 1704 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 57:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1714 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 59 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 5;}}
					
#line 1720 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 44:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1730 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 60 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 6;}}
					
#line 1736 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 50:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1746 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 61 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 7;}}
					
#line 1752 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 52:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1762 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 62 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 8;}}
					
#line 1768 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 49:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1778 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 63 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 9;}}
					
#line 1784 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 56:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1794 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 64 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 10;}}
					
#line 1800 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 55:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1810 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 65 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 11;}}
					
#line 1816 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 54:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1826 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 66 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 12;}}
					
#line 1832 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 58:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1842 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 67 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 13;}}
					
#line 1848 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 43:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1858 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 68 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 14;}}
					
#line 1864 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 46:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1874 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 69 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 15;}}
					
#line 1880 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 48:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1890 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 70 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 16;}}
					
#line 1896 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 59:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1906 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 71 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 17;}}
					
#line 1912 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 42:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1922 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 72 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 18;}}
					
#line 1928 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 47:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1938 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 73 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 19;}}
					
#line 1944 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 41:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1954 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 74 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 20;}}
					
#line 1960 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 53:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1970 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 75 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 21;}}
					
#line 1976 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 6:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1986 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 29;}}
					
#line 1992 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 33:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2002 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 30;}}
					
#line 2008 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 25:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2018 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 38;}}
					
#line 2024 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"


					break;
				}
				case 2:  {
					{
#line 1 "NONE"
						{te = p+1;}}

#line 2034 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"

					{
#line 100 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 41;}}

#line 2040 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"


					break;
				}
				case 13:  {
					{
#line 1 "NONE"
						{te = p+1;}}

#line 2050 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"

					{
#line 105 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 42;}}

#line 2056 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
			}
			
		}
		
		if ( p == eof ) {
			if ( cs >= 20 )
				goto _out;
		}
		else {
			switch ( _graphql_c_lexer_to_state_actions[cs] ) {
				case 10:  {
					{
#line 1 "NONE"
						{ts = 0;}}
					
#line 2076 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
