#line 1 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

#line 113 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"



#line 8 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
static const char _graphql_c_lexer_trans_keys[] = {
	2, 2, 5, 26, 8, 47, 18, 51,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 53, 8, 26, 8, 8, 8, 8,
	8, 26, 8, 8, 8, 8, 18, 19,
	14, 19, 18, 19, 16, 16, 3, 53,
	0, 0, 4, 4, 5, 5, 5, 26,
	8, 8, 8, 8, 8, 8, 8, 26,
	8, 8, 8, 8, 5, 6, 18, 19,
	16, 33, 18, 33, 18, 19, 16, 33,
	16, 16, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
	18, 50, 18, 50, 18, 50, 18, 50,
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
	1, 1, 6, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 4, 7, 8,
	9, 10, 1, 11, 1, 12, 13, 1,
	14, 4, 15, 16, 17, 18, 19, 19,
	19, 19, 19, 19, 19, 19, 19, 20,
	1, 1, 21, 1, 1, 22, 23, 23,
	23, 23, 24, 23, 23, 23, 23, 23,
	23, 23, 23, 23, 23, 23, 23, 23,
	23, 23, 23, 23, 23, 23, 23, 23,
	25, 26, 27, 1, 28, 1, 29, 30,
	31, 32, 33, 34, 35, 36, 37, 23,
	23, 38, 39, 40, 41, 42, 43, 44,
	45, 46, 47, 48, 23, 49, 50, 23,
	51, 52, 53, 0
};

static const short _graphql_c_lexer_index_offsets[] = {
	0, 1, 23, 63, 97, 130, 163, 196,
	229, 265, 284, 285, 286, 305, 306, 307,
	309, 315, 317, 318, 369, 370, 371, 372,
	394, 395, 396, 397, 416, 417, 418, 420,
	422, 440, 456, 458, 476, 477, 510, 543,
	576, 609, 642, 675, 708, 741, 774, 807,
	840, 873, 906, 939, 972, 1005, 1038, 1071,
	1104, 1137, 1170, 1203, 1236, 1269, 1302, 1335,
	1368, 1401, 1434, 1467, 1500, 1533, 1566, 1599,
	1632, 1665, 1698, 1731, 1764, 1797, 1830, 1863,
	1896, 1929, 1962, 1995, 2028, 2061, 2094, 2127,
	2160, 2193, 2226, 2259, 2292, 2325, 2358, 2391,
	2424, 2457, 2490, 2523, 2556, 2589, 2622, 2655,
	2688, 2721, 2754, 2787, 2820, 2853, 2886, 2919,
	2952, 2985, 3018, 3051, 3084, 3117, 3150, 3183,
	3216, 3249, 3282, 3315, 3348, 3381, 3414, 3447,
	3480, 3513, 3546, 3579, 0
};

static const short _graphql_c_lexer_indices[] = {
	1, 0, 0, 2, 3, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 4, 2,
	0, 0, 0, 0, 0, 0, 0, 0,
	2, 0, 0, 0, 0, 0, 0, 0,
	0, 2, 0, 0, 0, 2, 0, 0,
	0, 2, 0, 0, 0, 0, 0, 2,
	0, 0, 0, 2, 0, 2, 5, 6,
	6, 0, 0, 0, 6, 6, 0, 0,
	0, 0, 6, 6, 6, 6, 6, 6,
	6, 6, 6, 6, 6, 6, 6, 6,
	6, 6, 6, 6, 6, 6, 6, 6,
	7, 8, 8, 0, 0, 0, 8, 8,
	0, 0, 0, 0, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 9, 9, 0, 0, 0, 9,
	9, 0, 0, 0, 0, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 2, 2, 0, 0, 0,
	2, 2, 0, 0, 0, 0, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 10, 10, 0, 0,
	0, 10, 10, 0, 0, 0, 0, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 0,
	0, 0, 10, 10, 0, 0, 0, 0,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 0, 0,
	2, 13, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 14, 15, 16, 17, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	14, 18, 19, 21, 21, 22, 22, 11,
	11, 23, 23, 23, 23, 24, 27, 28,
	29, 30, 31, 32, 33, 34, 35, 36,
	37, 26, 38, 39, 26, 40, 41, 42,
	43, 44, 45, 45, 46, 26, 47, 45,
	45, 45, 45, 48, 49, 50, 45, 45,
	51, 45, 52, 53, 54, 45, 55, 56,
	57, 58, 59, 45, 45, 45, 60, 61,
	62, 64, 28, 29, 63, 63, 2, 67,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 2, 2, 2, 2, 2, 2, 2,
	2, 4, 12, 70, 71, 72, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 14,
	73, 16, 74, 74, 40, 41, 76, 75,
	75, 75, 75, 75, 75, 75, 77, 75,
	75, 75, 75, 75, 75, 75, 75, 77,
	21, 21, 78, 78, 78, 78, 77, 78,
	78, 78, 78, 78, 78, 78, 78, 77,
	23, 23, 76, 75, 41, 41, 75, 75,
	75, 75, 77, 75, 75, 75, 75, 75,
	75, 75, 75, 77, 79, 45, 45, 11,
	11, 11, 45, 45, 11, 11, 11, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 81, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 82, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 83,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 84, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 85, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 86, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 87, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 88, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 89, 45, 45, 45,
	45, 45, 45, 45, 45, 90, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 91, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 92, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 93, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 94, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 95, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 96, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	97, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 98,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 99, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 100, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 101,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 102, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 103, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	104, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 105, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 106, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 107, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 108, 109, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	110, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 111, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 112, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	113, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 114, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 115, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 116, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 117, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	118, 45, 45, 45, 119, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 120, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 121, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 122, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 123, 45,
	45, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 45, 124, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 125, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 126, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 127,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 128, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 129, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 130, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	131, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	132, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 133, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 134, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 135, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 136, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 137, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 138, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 139, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 140, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	141, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 142,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 143,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 144, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 145, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 146, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	147, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	148, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 149, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 150, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 151,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 152, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 153, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 154, 45, 45,
	45, 45, 45, 45, 155, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 156,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 157,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 158,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 159, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 160, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 161, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 162, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 163, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	164, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 165, 45,
	45, 45, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	166, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 167, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 168, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 169, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	170, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	171, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 172, 45, 45,
	45, 45, 45, 173, 45, 45, 80, 80,
	80, 45, 45, 80, 80, 80, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 174, 45, 45, 45, 45, 45, 80,
	80, 80, 45, 45, 80, 80, 80, 45,
	45, 45, 45, 45, 175, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	80, 80, 80, 45, 45, 80, 80, 80,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 176, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 80, 80, 45, 45, 80, 80,
	80, 45, 45, 45, 45, 45, 177, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 80, 80, 80, 45, 45, 80,
	80, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 178, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 80, 80, 80, 45, 45,
	80, 80, 80, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 179, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 80, 80, 80, 45,
	45, 80, 80, 80, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 180, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 80, 80, 80,
	45, 45, 80, 80, 80, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 181, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 0
};

static const signed char _graphql_c_lexer_index_defaults[] = {
	0, 2, 0, 0, 0, 0, 0, 0,
	0, 12, 12, 12, 12, 12, 12, 20,
	11, 11, 0, 26, 63, 65, 66, 2,
	68, 69, 69, 12, 12, 12, 33, 63,
	75, 78, 78, 75, 63, 11, 80, 80,
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

static const short _graphql_c_lexer_cond_targs[] = {
	19, 19, 1, 19, 2, 3, 4, 7,
	5, 6, 8, 19, 9, 10, 12, 11,
	25, 13, 14, 27, 19, 33, 17, 34,
	19, 19, 19, 20, 21, 19, 22, 19,
	23, 30, 19, 19, 19, 19, 31, 36,
	32, 35, 19, 19, 19, 37, 19, 19,
	38, 46, 53, 63, 81, 88, 91, 92,
	96, 105, 123, 128, 19, 19, 19, 19,
	0, 19, 19, 24, 19, 19, 26, 19,
	28, 29, 19, 19, 15, 16, 19, 18,
	19, 39, 40, 41, 42, 43, 44, 45,
	37, 47, 49, 48, 37, 50, 51, 52,
	37, 54, 57, 55, 56, 37, 58, 59,
	60, 61, 62, 37, 64, 72, 65, 66,
	67, 68, 69, 70, 71, 37, 73, 75,
	74, 37, 76, 77, 78, 79, 80, 37,
	82, 83, 84, 85, 86, 87, 37, 89,
	90, 37, 37, 93, 94, 95, 37, 97,
	98, 99, 100, 101, 102, 103, 104, 37,
	106, 113, 107, 110, 108, 109, 37, 111,
	112, 37, 114, 115, 116, 117, 118, 119,
	120, 121, 122, 37, 124, 126, 125, 37,
	127, 37, 129, 130, 131, 37, 0
};

static const signed char _graphql_c_lexer_cond_actions[] = {
	1, 2, 0, 3, 0, 0, 0, 0,
	0, 0, 0, 4, 0, 0, 0, 0,
	0, 0, 0, 5, 6, 7, 0, 0,
	8, 0, 11, 12, 0, 13, 0, 14,
	12, 0, 15, 16, 17, 18, 0, 12,
	19, 19, 20, 21, 22, 23, 24, 25,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 26, 27, 28, 29,
	0, 30, 31, 32, 33, 34, 0, 35,
	5, 5, 36, 37, 0, 0, 38, 0,
	39, 0, 0, 0, 0, 0, 0, 0,
	40, 0, 0, 0, 41, 0, 0, 0,
	42, 0, 0, 0, 0, 43, 0, 0,
	0, 0, 0, 44, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 45, 0, 0,
	0, 46, 0, 0, 0, 0, 0, 47,
	0, 0, 0, 0, 0, 0, 48, 0,
	0, 49, 50, 0, 0, 0, 51, 0,
	0, 0, 0, 0, 0, 0, 0, 52,
	0, 0, 0, 0, 0, 0, 53, 0,
	0, 54, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 55, 0, 0, 0, 56,
	0, 57, 0, 0, 0, 58, 0
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
	0, 0, 0, 0, 0
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
	0, 0, 0, 0, 0
};

static const signed char _graphql_c_lexer_eof_trans[] = {
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 12, 12, 12, 12, 12, 12, 21,
	12, 12, 1, 26, 64, 66, 67, 64,
	69, 70, 70, 70, 70, 70, 75, 64,
	76, 79, 79, 76, 64, 12, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 81, 81, 81, 81,
	81, 81, 81, 81, 0
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
		line_incr = FIX2INT(rb_funcall(token_content, rb_intern("count"), 1, rb_utf8_str_new_cstr("\n")));
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
	
	
#line 1008 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
	{
		cs = (int)graphql_c_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
	}
	
#line 433 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
#line 1019 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
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
				
#line 1034 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
				
				
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
					
#line 1072 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 28:  {
					{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 77 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RCURLY, ts, te, meta); }
						}}
					
#line 1085 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 26:  {
					{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 78 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LCURLY, ts, te, meta); }
						}}
					
#line 1098 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 18:  {
					{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 79 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RPAREN, ts, te, meta); }
						}}
					
#line 1111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 17:  {
					{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 80 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LPAREN, ts, te, meta); }
						}}
					
#line 1124 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 25:  {
					{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 81 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(RBRACKET, ts, te, meta); }
						}}
					
#line 1137 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 24:  {
					{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 82 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(LBRACKET, ts, te, meta); }
						}}
					
#line 1150 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 20:  {
					{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 83 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COLON, ts, te, meta); }
						}}
					
#line 1163 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 35:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1176 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 3:  {
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1189 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 15:  {
					{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 86 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(VAR_SIGN, ts, te, meta); }
						}}
					
#line 1202 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 22:  {
					{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 87 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(DIR_SIGN, ts, te, meta); }
						}}
					
#line 1215 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 8:  {
					{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 88 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(ELLIPSIS, ts, te, meta); }
						}}
					
#line 1228 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 21:  {
					{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 89 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(EQUALS, ts, te, meta); }
						}}
					
#line 1241 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 14:  {
					{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 90 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BANG, ts, te, meta); }
						}}
					
#line 1254 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 27:  {
					{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 91 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(PIPE, ts, te, meta); }
						}}
					
#line 1267 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 16:  {
					{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 92 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(AMP, ts, te, meta); }
						}}
					
#line 1280 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
					
#line 1297 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
					
#line 1313 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"

					
					break; 
				}
				case 11:  {
					{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p+1;{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1326 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 37:  {
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(INT_LITERAL, ts, te, meta); }
						}}
					
#line 1339 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 38:  {
					{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(FLOAT_LITERAL, ts, te, meta); }
						}}
					
#line 1352 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 34:  {
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1365 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 33:  {
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1378 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 39:  {
					{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(IDENTIFIER, ts, te, meta); }
						}}
					
#line 1391 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 36:  {
					{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 94 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(COMMENT, ts, te, meta); }
						}}
					
#line 1404 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"


					break;
				}
				case 31:  {
					{
#line 95 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 95 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"

								meta->line += 1;
								meta->col = 1;
								meta->preceeded_by_number = 0;
							}
						}}

#line 1421 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
					
#line 1437 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 29:  {
					{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 111 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1450 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
					
#line 1464 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
					
#line 1478 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
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
					
#line 1658 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 19:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1668 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 56 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 1;}}
					
#line 1674 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 7:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1684 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 57 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 2;}}
					
#line 1690 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 50:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1700 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 58 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 3;}}
					
#line 1706 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 44:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1716 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 59 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 4;}}
					
#line 1722 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 56:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1732 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 60 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 5;}}
					
#line 1738 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 43:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1748 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 61 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 6;}}
					
#line 1754 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 49:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1764 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 62 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 7;}}
					
#line 1770 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 51:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1780 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 63 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 8;}}
					
#line 1786 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 48:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1796 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 64 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 9;}}
					
#line 1802 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 55:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1812 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 65 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 10;}}
					
#line 1818 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 54:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1828 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 66 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 11;}}
					
#line 1834 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 53:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1844 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 67 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 12;}}
					
#line 1850 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 57:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1860 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 68 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 13;}}
					
#line 1866 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 42:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1876 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 69 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 14;}}
					
#line 1882 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 45:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1892 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 70 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 15;}}
					
#line 1898 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 47:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1908 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 71 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 16;}}
					
#line 1914 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 58:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1924 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 72 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 17;}}
					
#line 1930 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 41:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1940 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 73 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 18;}}
					
#line 1946 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 46:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1956 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 74 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 19;}}
					
#line 1962 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 40:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1972 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 75 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 20;}}
					
#line 1978 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 52:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1988 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 76 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 21;}}
					
#line 1994 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 5:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2004 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 84 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 29;}}
					
#line 2010 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 32:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2020 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 85 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 30;}}
					
#line 2026 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
				case 23:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 2036 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					{
#line 93 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
						{act = 38;}}
					
#line 2042 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"


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
					
#line 2062 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.c"
					
					
					break; 
				}
			}
			
			p += 1;
			goto _resume;
		}
		_out: {}
	}
	
#line 434 "graphql-c_parser/ext/graphql_c_parser_ext/lexer.rl"
	
	
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
