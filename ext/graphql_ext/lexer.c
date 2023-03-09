#line 1 "ext/graphql_ext/lexer.rl"

#line 102 "ext/graphql_ext/lexer.rl"



#line 8 "ext/graphql_ext/lexer.c"
static const char _graphql_c_lexer_trans_keys[] = {
	4, 22, 4, 43, 14, 47, 14, 46,
	14, 46, 14, 46, 14, 46, 14, 46,
	14, 46, 14, 46, 14, 49, 4, 22,
	4, 4, 4, 4, 4, 22, 4, 4,
	4, 4, 14, 15, 14, 15, 10, 15,
	12, 12, 0, 49, 0, 0, 4, 22,
	4, 4, 4, 4, 4, 4, 4, 22,
	4, 4, 4, 4, 1, 1, 14, 15,
	10, 29, 14, 15, 10, 29, 10, 29,
	12, 12, 14, 46, 14, 46, 14, 46,
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
	0
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
	0, 19, 59, 93, 126, 159, 192, 225,
	258, 291, 324, 360, 379, 380, 381, 400,
	401, 402, 404, 406, 412, 413, 463, 464,
	483, 484, 485, 486, 505, 506, 507, 508,
	510, 530, 532, 552, 572, 573, 606, 639,
	672, 705, 738, 771, 804, 837, 870, 903,
	936, 969, 1002, 1035, 1068, 1101, 1134, 1167,
	1200, 1233, 1266, 1299, 1332, 1365, 1398, 1431,
	1464, 1497, 1530, 1563, 1596, 1629, 1662, 1695,
	1728, 1761, 1794, 1827, 1860, 1893, 1926, 1959,
	1992, 2025, 2058, 2091, 2124, 2157, 2190, 2223,
	2256, 2289, 2322, 2355, 2388, 2421, 2454, 2487,
	2520, 2553, 2586, 2619, 2652, 2685, 2718, 2751,
	2784, 2817, 2850, 2883, 2916, 2949, 2982, 3015,
	3048, 3081, 3114, 3147, 3180, 3213, 3246, 3279,
	3312, 3345, 3378, 3411, 3444, 3477, 3510, 3543,
	3576, 3609, 3642, 3675, 0
};

static const short _graphql_c_lexer_indices[] = {
	2, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 3, 1, 0, 0, 0, 0,
	0, 0, 0, 0, 1, 0, 0, 0,
	0, 0, 0, 0, 0, 1, 0, 0,
	0, 1, 0, 0, 0, 1, 0, 0,
	0, 0, 0, 1, 0, 0, 0, 1,
	0, 1, 4, 5, 5, 0, 0, 0,
	5, 5, 0, 0, 0, 0, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 5, 5, 5, 5,
	5, 5, 5, 5, 6, 7, 7, 0,
	0, 0, 7, 7, 0, 0, 0, 0,
	7, 7, 7, 7, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 8, 8,
	0, 0, 0, 8, 8, 0, 0, 0,
	0, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 8,
	8, 8, 8, 8, 8, 8, 8, 1,
	1, 0, 0, 0, 1, 1, 0, 0,
	0, 0, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	9, 9, 0, 0, 0, 9, 9, 0,
	0, 0, 0, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 9, 9, 9, 9, 9, 9, 9,
	9, 10, 10, 0, 0, 0, 10, 10,
	0, 0, 0, 0, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 10, 10, 10, 10, 10, 10,
	10, 10, 11, 11, 0, 0, 0, 11,
	11, 0, 0, 0, 0, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 11, 11, 11, 11, 11,
	11, 11, 11, 12, 12, 0, 0, 0,
	12, 12, 0, 0, 0, 0, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 0, 0,
	0, 12, 12, 0, 0, 0, 0, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 12, 12, 12,
	12, 12, 12, 12, 12, 0, 0, 1,
	15, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 16, 17, 18, 19, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 16,
	20, 21, 22, 22, 24, 24, 25, 25,
	13, 13, 22, 22, 26, 29, 30, 28,
	31, 32, 33, 34, 35, 36, 37, 28,
	38, 39, 28, 40, 41, 42, 43, 44,
	45, 45, 46, 28, 47, 45, 45, 45,
	45, 48, 49, 50, 45, 45, 51, 45,
	52, 53, 54, 45, 55, 56, 57, 58,
	59, 45, 45, 45, 60, 61, 62, 29,
	65, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 1, 1, 1, 1, 1, 1,
	1, 1, 3, 14, 68, 69, 70, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	14, 14, 14, 14, 14, 14, 14, 14,
	16, 71, 18, 72, 40, 41, 25, 25,
	74, 73, 22, 22, 73, 73, 73, 73,
	75, 73, 73, 73, 73, 73, 73, 73,
	73, 75, 22, 22, 25, 25, 76, 76,
	24, 24, 76, 76, 76, 76, 75, 76,
	76, 76, 76, 76, 76, 76, 76, 75,
	25, 25, 74, 73, 41, 41, 73, 73,
	73, 73, 75, 73, 73, 73, 73, 73,
	73, 73, 73, 75, 77, 45, 45, 13,
	13, 13, 45, 45, 13, 13, 13, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 79, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 80, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 81,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 82, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 83, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 84, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 85, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 86, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 87, 45, 45, 45,
	45, 45, 45, 45, 45, 88, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 89, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 90, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 91, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 92, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 93, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 94, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	95, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 96,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 97, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 98, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 99,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 100, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 101, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	102, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 103, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 104, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 105, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 106, 107, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	108, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 109, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 110, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	111, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 112, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 113, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 114, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 115, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	116, 45, 45, 45, 117, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 118, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 119, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 120, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 121, 45,
	45, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 45, 122, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 123, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 124, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 125,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 126, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 127, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 128, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	129, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	130, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 131, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 132, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 133, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 134, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 135, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 136, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 137, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 138, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	139, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 140,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 141,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 142, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 143, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 144, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	145, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	146, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 147, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 148, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 149,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 150, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 151, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 152, 45, 45,
	45, 45, 45, 45, 153, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 154,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 155,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 156,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 157, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 158, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 159, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 160, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 161, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	162, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 163, 45,
	45, 45, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	164, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 165, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 166, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 167, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	168, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	169, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 170, 45, 45,
	45, 45, 45, 171, 45, 45, 78, 78,
	78, 45, 45, 78, 78, 78, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 172, 45, 45, 45, 45, 45, 78,
	78, 78, 45, 45, 78, 78, 78, 45,
	45, 45, 45, 45, 173, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	78, 78, 78, 45, 45, 78, 78, 78,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 174, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 78, 78, 78, 45, 45, 78, 78,
	78, 45, 45, 45, 45, 45, 175, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 78, 78, 78, 45, 45, 78,
	78, 78, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 176, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 78, 78, 78, 45, 45,
	78, 78, 78, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 177, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 78, 78, 78, 45,
	45, 78, 78, 78, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 178, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 45, 78, 78, 78,
	45, 45, 78, 78, 78, 45, 45, 45,
	45, 45, 45, 45, 45, 45, 45, 45,
	45, 179, 45, 45, 45, 45, 45, 45,
	45, 45, 45, 45, 0
};

static const signed char _graphql_c_lexer_index_defaults[] = {
	1, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 14, 14, 14, 14, 14,
	14, 13, 23, 13, 0, 28, 63, 1,
	66, 67, 67, 14, 14, 14, 33, 64,
	73, 76, 76, 73, 64, 13, 78, 78,
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
	78, 78, 78, 78, 0
};

static const short _graphql_c_lexer_cond_targs[] = {
	21, 0, 21, 1, 2, 3, 6, 4,
	5, 7, 8, 9, 10, 21, 11, 12,
	14, 13, 25, 15, 16, 27, 33, 21,
	34, 17, 21, 21, 21, 22, 21, 21,
	23, 30, 21, 21, 21, 21, 31, 36,
	32, 35, 21, 21, 21, 37, 21, 21,
	38, 46, 53, 63, 81, 88, 91, 92,
	96, 105, 123, 128, 21, 21, 21, 21,
	21, 24, 21, 21, 26, 21, 28, 29,
	21, 21, 18, 19, 21, 20, 21, 39,
	40, 41, 42, 43, 44, 45, 37, 47,
	49, 48, 37, 50, 51, 52, 37, 54,
	57, 55, 56, 37, 58, 59, 60, 61,
	62, 37, 64, 72, 65, 66, 67, 68,
	69, 70, 71, 37, 73, 75, 74, 37,
	76, 77, 78, 79, 80, 37, 82, 83,
	84, 85, 86, 87, 37, 89, 90, 37,
	37, 93, 94, 95, 37, 97, 98, 99,
	100, 101, 102, 103, 104, 37, 106, 113,
	107, 110, 108, 109, 37, 111, 112, 37,
	114, 115, 116, 117, 118, 119, 120, 121,
	122, 37, 124, 126, 125, 37, 127, 37,
	129, 130, 131, 37, 0
};

static const signed char _graphql_c_lexer_cond_actions[] = {
	1, 0, 2, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 3, 0, 0,
	0, 0, 0, 0, 0, 4, 0, 5,
	6, 0, 7, 0, 10, 0, 11, 12,
	13, 0, 14, 15, 16, 17, 0, 13,
	18, 18, 19, 20, 21, 22, 23, 24,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 25, 26, 27, 28,
	29, 30, 31, 32, 0, 33, 4, 4,
	34, 35, 0, 0, 36, 0, 37, 0,
	0, 0, 0, 0, 0, 0, 38, 0,
	0, 0, 39, 0, 0, 0, 40, 0,
	0, 0, 0, 41, 0, 0, 0, 0,
	0, 42, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 43, 0, 0, 0, 44,
	0, 0, 0, 0, 0, 45, 0, 0,
	0, 0, 0, 0, 46, 0, 0, 47,
	48, 0, 0, 0, 49, 0, 0, 0,
	0, 0, 0, 0, 0, 50, 0, 0,
	0, 0, 0, 0, 51, 0, 0, 52,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 53, 0, 0, 0, 54, 0, 55,
	0, 0, 0, 56, 0
};

static const signed char _graphql_c_lexer_to_state_actions[] = {
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 8, 0, 0,
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
	0, 0, 0, 0, 0, 9, 0, 0,
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
	1, 1, 1, 14, 14, 14, 14, 14,
	14, 14, 24, 14, 1, 28, 64, 65,
	67, 68, 68, 68, 68, 68, 73, 65,
	74, 77, 77, 74, 65, 14, 79, 79,
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

static const int graphql_c_lexer_start = 21;
static const int graphql_c_lexer_first_final = 21;
static const int graphql_c_lexer_error = -1;

static const int graphql_c_lexer_en_main = 21;


#line 104 "ext/graphql_ext/lexer.rl"


#include <ruby.h>

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
	INT,
	FLOAT,
	ON,
	FRAGMENT,
	TRUE_LITERAL,
	FALSE_LITERAL,
	NULL_LITERAL,
	QUERY,
	MUTATION,
	SUBSCRIPTION,
	SCHEMA,
	SCALAR,
	TYPE_LITERAL,
	EXTEND,
	IMPLEMENTS,
	INTERFACE,
	UNION,
	ENUM,
	INPUT,
	DIRECTIVE,
	REPEATABLE,
	RCURLY,
	LCURLY,
	RPAREN,
	LPAREN,
	RBRACKET,
	LBRACKET,
	COLON,
	QUOTED_STRING,
	BLOCK_STRING,
	VAR_SIGN,
	DIR_SIGN,
	ELLIPSIS,
	EQUALS,
	BANG,
	PIPE,
	AMP,
	IDENTIFIER,
	COMMENT,
	UNKNOWN_CHAR
} TokenType;

typedef struct Meta {
	int line;
	int col;
	char *query_cstr;
	char *pe;
	VALUE tokens;
	VALUE previous_token;
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
	int quotes_length = 0; // set by string tokens below
	int line_incr = 0;
	VALUE token_sym = Qnil;
	VALUE token_content = Qnil;
	
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
		DYNAMIC_VALUE_TOKEN(IDENTIFIER)
		DYNAMIC_VALUE_TOKEN(INT)
		DYNAMIC_VALUE_TOKEN(FLOAT)
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
		line_incr = FIX2INT(rb_funcall(token_content, rb_intern("count"), 1, rb_str_new_cstr("\n")));
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
			}
			
			if (
				RB_TEST(rb_funcall(token_content, rb_intern("valid_encoding?"), 0)) &&
			RB_TEST(rb_funcall(token_content, rb_intern("match?"), 1, valid_string_pattern))
			) {
				rb_funcall(mGraphQLLanguageLexer, rb_intern("replace_escaped_characters_in_place"), 1, token_content);
				if (!RB_TEST(rb_funcall(token_content, rb_intern("valid_encoding?"), 0))) {
					token_sym = ID2SYM(rb_intern("BAD_UNICODE_ESCAPE"));
				}
				
				
			} else {
				token_sym = ID2SYM(rb_intern("BAD_UNICODE_ESCAPE"));
			}
		}
		
		VALUE token_data[5] = {
			token_sym,
			rb_int2inum(meta->line),
			rb_int2inum(meta->col),
			token_content,
			meta->previous_token,
		};
		VALUE token = rb_ary_new_from_values(5, token_data);
		// COMMENTs are retained as `previous_token` but aren't pushed to the normal token list
		if (tt != COMMENT) {
			rb_ary_push(meta->tokens, token);
		}
		meta->previous_token = token;
	}
	// Bump the column counter for the next token
	meta->col += te - ts;
	meta->line += line_incr;
}

VALUE tokenize(VALUE query_rbstr) {
	int cs = 0;
	int act = 0;
	char *p = StringValueCStr(query_rbstr);
	char *pe = p + strlen(p);
	char *eof = pe;
	char *ts = 0;
	char *te = 0;
	VALUE tokens = rb_ary_new();
	struct Meta meta_s = {1, 1, p, pe, tokens, Qnil};
	Meta *meta = &meta_s;
	
	
#line 932 "ext/graphql_ext/lexer.c"
	{
		cs = (int)graphql_c_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
	}
	
#line 344 "ext/graphql_ext/lexer.rl"
	
	
#line 943 "ext/graphql_ext/lexer.c"
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
				
#line 958 "ext/graphql_ext/lexer.c"
				
				
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
					
#line 996 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 27:  {
					{
#line 75 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 75 "ext/graphql_ext/lexer.rl"
								emit(RCURLY, ts, te, meta); }
						}}
					
#line 1009 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 25:  {
					{
#line 76 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 76 "ext/graphql_ext/lexer.rl"
								emit(LCURLY, ts, te, meta); }
						}}
					
#line 1022 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 17:  {
					{
#line 77 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 77 "ext/graphql_ext/lexer.rl"
								emit(RPAREN, ts, te, meta); }
						}}
					
#line 1035 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 16:  {
					{
#line 78 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 78 "ext/graphql_ext/lexer.rl"
								emit(LPAREN, ts, te, meta); }
						}}
					
#line 1048 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 24:  {
					{
#line 79 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 79 "ext/graphql_ext/lexer.rl"
								emit(RBRACKET, ts, te, meta); }
						}}
					
#line 1061 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 23:  {
					{
#line 80 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 80 "ext/graphql_ext/lexer.rl"
								emit(LBRACKET, ts, te, meta); }
						}}
					
#line 1074 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 19:  {
					{
#line 81 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 81 "ext/graphql_ext/lexer.rl"
								emit(COLON, ts, te, meta); }
						}}
					
#line 1087 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 33:  {
					{
#line 82 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 82 "ext/graphql_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1100 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 2:  {
					{
#line 83 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 83 "ext/graphql_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1113 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 14:  {
					{
#line 84 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 84 "ext/graphql_ext/lexer.rl"
								emit(VAR_SIGN, ts, te, meta); }
						}}
					
#line 1126 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 21:  {
					{
#line 85 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 85 "ext/graphql_ext/lexer.rl"
								emit(DIR_SIGN, ts, te, meta); }
						}}
					
#line 1139 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 7:  {
					{
#line 86 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 86 "ext/graphql_ext/lexer.rl"
								emit(ELLIPSIS, ts, te, meta); }
						}}
					
#line 1152 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 20:  {
					{
#line 87 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 87 "ext/graphql_ext/lexer.rl"
								emit(EQUALS, ts, te, meta); }
						}}
					
#line 1165 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 12:  {
					{
#line 88 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 88 "ext/graphql_ext/lexer.rl"
								emit(BANG, ts, te, meta); }
						}}
					
#line 1178 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 26:  {
					{
#line 89 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 89 "ext/graphql_ext/lexer.rl"
								emit(PIPE, ts, te, meta); }
						}}
					
#line 1191 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 15:  {
					{
#line 90 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 90 "ext/graphql_ext/lexer.rl"
								emit(AMP, ts, te, meta); }
						}}
					
#line 1204 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 11:  {
					{
#line 93 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 93 "ext/graphql_ext/lexer.rl"
								
								meta->line += 1;
								meta->col = 1;
							}
						}}
					
#line 1220 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 10:  {
					{
#line 100 "ext/graphql_ext/lexer.rl"
						{te = p+1;{
#line 100 "ext/graphql_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1233 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 35:  {
					{
#line 54 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 54 "ext/graphql_ext/lexer.rl"
								emit(INT, ts, te, meta); }
						}}
					
#line 1246 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 36:  {
					{
#line 55 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 55 "ext/graphql_ext/lexer.rl"
								emit(FLOAT, ts, te, meta); }
						}}
					
#line 1259 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 32:  {
					{
#line 82 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 82 "ext/graphql_ext/lexer.rl"
								emit(BLOCK_STRING, ts, te, meta); }
						}}
					
#line 1272 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 31:  {
					{
#line 83 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 83 "ext/graphql_ext/lexer.rl"
								emit(QUOTED_STRING, ts, te, meta); }
						}}
					
#line 1285 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 37:  {
					{
#line 91 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 91 "ext/graphql_ext/lexer.rl"
								emit(IDENTIFIER, ts, te, meta); }
						}}
					
#line 1298 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 34:  {
					{
#line 92 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 92 "ext/graphql_ext/lexer.rl"
								emit(COMMENT, ts, te, meta); }
						}}
					
#line 1311 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 28:  {
					{
#line 98 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 98 "ext/graphql_ext/lexer.rl"
								meta->col += te - ts; }
						}}
					
#line 1324 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 29:  {
					{
#line 100 "ext/graphql_ext/lexer.rl"
						{te = p;p = p - 1;{
#line 100 "ext/graphql_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1337 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 5:  {
					{
#line 54 "ext/graphql_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 54 "ext/graphql_ext/lexer.rl"
								emit(INT, ts, te, meta); }
						}}
					
#line 1351 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 1:  {
					{
#line 100 "ext/graphql_ext/lexer.rl"
						{p = ((te))-1;
							{
#line 100 "ext/graphql_ext/lexer.rl"
								emit(UNKNOWN_CHAR, ts, te, meta); }
						}}
					
#line 1365 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 3:  {
					{
#line 1 "NONE"
						{switch( act ) {
								case 1:  {
									p = ((te))-1;
									{
#line 54 "ext/graphql_ext/lexer.rl"
										emit(INT, ts, te, meta); }
									break; 
								}
								case 2:  {
									p = ((te))-1;
									{
#line 55 "ext/graphql_ext/lexer.rl"
										emit(FLOAT, ts, te, meta); }
									break; 
								}
								case 3:  {
									p = ((te))-1;
									{
#line 56 "ext/graphql_ext/lexer.rl"
										emit(ON, ts, te, meta); }
									break; 
								}
								case 4:  {
									p = ((te))-1;
									{
#line 57 "ext/graphql_ext/lexer.rl"
										emit(FRAGMENT, ts, te, meta); }
									break; 
								}
								case 5:  {
									p = ((te))-1;
									{
#line 58 "ext/graphql_ext/lexer.rl"
										emit(TRUE_LITERAL, ts, te, meta); }
									break; 
								}
								case 6:  {
									p = ((te))-1;
									{
#line 59 "ext/graphql_ext/lexer.rl"
										emit(FALSE_LITERAL, ts, te, meta); }
									break; 
								}
								case 7:  {
									p = ((te))-1;
									{
#line 60 "ext/graphql_ext/lexer.rl"
										emit(NULL_LITERAL, ts, te, meta); }
									break; 
								}
								case 8:  {
									p = ((te))-1;
									{
#line 61 "ext/graphql_ext/lexer.rl"
										emit(QUERY, ts, te, meta); }
									break; 
								}
								case 9:  {
									p = ((te))-1;
									{
#line 62 "ext/graphql_ext/lexer.rl"
										emit(MUTATION, ts, te, meta); }
									break; 
								}
								case 10:  {
									p = ((te))-1;
									{
#line 63 "ext/graphql_ext/lexer.rl"
										emit(SUBSCRIPTION, ts, te, meta); }
									break; 
								}
								case 11:  {
									p = ((te))-1;
									{
#line 64 "ext/graphql_ext/lexer.rl"
										emit(SCHEMA, ts, te, meta); }
									break; 
								}
								case 12:  {
									p = ((te))-1;
									{
#line 65 "ext/graphql_ext/lexer.rl"
										emit(SCALAR, ts, te, meta); }
									break; 
								}
								case 13:  {
									p = ((te))-1;
									{
#line 66 "ext/graphql_ext/lexer.rl"
										emit(TYPE_LITERAL, ts, te, meta); }
									break; 
								}
								case 14:  {
									p = ((te))-1;
									{
#line 67 "ext/graphql_ext/lexer.rl"
										emit(EXTEND, ts, te, meta); }
									break; 
								}
								case 15:  {
									p = ((te))-1;
									{
#line 68 "ext/graphql_ext/lexer.rl"
										emit(IMPLEMENTS, ts, te, meta); }
									break; 
								}
								case 16:  {
									p = ((te))-1;
									{
#line 69 "ext/graphql_ext/lexer.rl"
										emit(INTERFACE, ts, te, meta); }
									break; 
								}
								case 17:  {
									p = ((te))-1;
									{
#line 70 "ext/graphql_ext/lexer.rl"
										emit(UNION, ts, te, meta); }
									break; 
								}
								case 18:  {
									p = ((te))-1;
									{
#line 71 "ext/graphql_ext/lexer.rl"
										emit(ENUM, ts, te, meta); }
									break; 
								}
								case 19:  {
									p = ((te))-1;
									{
#line 72 "ext/graphql_ext/lexer.rl"
										emit(INPUT, ts, te, meta); }
									break; 
								}
								case 20:  {
									p = ((te))-1;
									{
#line 73 "ext/graphql_ext/lexer.rl"
										emit(DIRECTIVE, ts, te, meta); }
									break; 
								}
								case 21:  {
									p = ((te))-1;
									{
#line 74 "ext/graphql_ext/lexer.rl"
										emit(REPEATABLE, ts, te, meta); }
									break; 
								}
								case 29:  {
									p = ((te))-1;
									{
#line 82 "ext/graphql_ext/lexer.rl"
										emit(BLOCK_STRING, ts, te, meta); }
									break; 
								}
								case 30:  {
									p = ((te))-1;
									{
#line 83 "ext/graphql_ext/lexer.rl"
										emit(QUOTED_STRING, ts, te, meta); }
									break; 
								}
								case 38:  {
									p = ((te))-1;
									{
#line 91 "ext/graphql_ext/lexer.rl"
										emit(IDENTIFIER, ts, te, meta); }
									break; 
								}
							}}
					}
					
#line 1545 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 18:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1555 "ext/graphql_ext/lexer.c"
					
					{
#line 54 "ext/graphql_ext/lexer.rl"
						{act = 1;}}
					
#line 1561 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 6:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1571 "ext/graphql_ext/lexer.c"
					
					{
#line 55 "ext/graphql_ext/lexer.rl"
						{act = 2;}}
					
#line 1577 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 48:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1587 "ext/graphql_ext/lexer.c"
					
					{
#line 56 "ext/graphql_ext/lexer.rl"
						{act = 3;}}
					
#line 1593 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 42:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1603 "ext/graphql_ext/lexer.c"
					
					{
#line 57 "ext/graphql_ext/lexer.rl"
						{act = 4;}}
					
#line 1609 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 54:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1619 "ext/graphql_ext/lexer.c"
					
					{
#line 58 "ext/graphql_ext/lexer.rl"
						{act = 5;}}
					
#line 1625 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 41:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1635 "ext/graphql_ext/lexer.c"
					
					{
#line 59 "ext/graphql_ext/lexer.rl"
						{act = 6;}}
					
#line 1641 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 47:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1651 "ext/graphql_ext/lexer.c"
					
					{
#line 60 "ext/graphql_ext/lexer.rl"
						{act = 7;}}
					
#line 1657 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 49:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1667 "ext/graphql_ext/lexer.c"
					
					{
#line 61 "ext/graphql_ext/lexer.rl"
						{act = 8;}}
					
#line 1673 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 46:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1683 "ext/graphql_ext/lexer.c"
					
					{
#line 62 "ext/graphql_ext/lexer.rl"
						{act = 9;}}
					
#line 1689 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 53:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1699 "ext/graphql_ext/lexer.c"
					
					{
#line 63 "ext/graphql_ext/lexer.rl"
						{act = 10;}}
					
#line 1705 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 52:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1715 "ext/graphql_ext/lexer.c"
					
					{
#line 64 "ext/graphql_ext/lexer.rl"
						{act = 11;}}
					
#line 1721 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 51:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1731 "ext/graphql_ext/lexer.c"
					
					{
#line 65 "ext/graphql_ext/lexer.rl"
						{act = 12;}}
					
#line 1737 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 55:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1747 "ext/graphql_ext/lexer.c"
					
					{
#line 66 "ext/graphql_ext/lexer.rl"
						{act = 13;}}
					
#line 1753 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 40:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1763 "ext/graphql_ext/lexer.c"
					
					{
#line 67 "ext/graphql_ext/lexer.rl"
						{act = 14;}}
					
#line 1769 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 43:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1779 "ext/graphql_ext/lexer.c"
					
					{
#line 68 "ext/graphql_ext/lexer.rl"
						{act = 15;}}
					
#line 1785 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 45:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1795 "ext/graphql_ext/lexer.c"
					
					{
#line 69 "ext/graphql_ext/lexer.rl"
						{act = 16;}}
					
#line 1801 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 56:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1811 "ext/graphql_ext/lexer.c"
					
					{
#line 70 "ext/graphql_ext/lexer.rl"
						{act = 17;}}
					
#line 1817 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 39:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1827 "ext/graphql_ext/lexer.c"
					
					{
#line 71 "ext/graphql_ext/lexer.rl"
						{act = 18;}}
					
#line 1833 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 44:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1843 "ext/graphql_ext/lexer.c"
					
					{
#line 72 "ext/graphql_ext/lexer.rl"
						{act = 19;}}
					
#line 1849 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 38:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1859 "ext/graphql_ext/lexer.c"
					
					{
#line 73 "ext/graphql_ext/lexer.rl"
						{act = 20;}}
					
#line 1865 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 50:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1875 "ext/graphql_ext/lexer.c"
					
					{
#line 74 "ext/graphql_ext/lexer.rl"
						{act = 21;}}
					
#line 1881 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 4:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1891 "ext/graphql_ext/lexer.c"
					
					{
#line 82 "ext/graphql_ext/lexer.rl"
						{act = 29;}}
					
#line 1897 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 30:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1907 "ext/graphql_ext/lexer.c"
					
					{
#line 83 "ext/graphql_ext/lexer.rl"
						{act = 30;}}
					
#line 1913 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
				case 22:  {
					{
#line 1 "NONE"
						{te = p+1;}}
					
#line 1923 "ext/graphql_ext/lexer.c"
					
					{
#line 91 "ext/graphql_ext/lexer.rl"
						{act = 38;}}
					
#line 1929 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
			}
			
		}
		
		if ( p == eof ) {
			if ( cs >= 21 )
				goto _out;
		}
		else {
			switch ( _graphql_c_lexer_to_state_actions[cs] ) {
				case 8:  {
					{
#line 1 "NONE"
						{ts = 0;}}
					
#line 1949 "ext/graphql_ext/lexer.c"
					
					
					break; 
				}
			}
			
			p += 1;
			goto _resume;
		}
		_out: {}
	}
	
#line 345 "ext/graphql_ext/lexer.rl"
	
	
	return tokens;
}


#define SETUP_STATIC_TOKEN_VARIABLE(token_name, token_content) \
GraphQLTokenString##token_name = rb_str_new_cstr(token_content); \
rb_funcall(GraphQLTokenString##token_name, rb_intern("-@"), 0); \
rb_global_variable(&GraphQLTokenString##token_name); \

#define SETUP_STATIC_STRING(var_name, str_content) \
var_name = rb_str_new_cstr(str_content); \
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
