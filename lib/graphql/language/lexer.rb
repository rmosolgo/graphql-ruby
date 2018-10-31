module GraphQL
module Language
module Lexer
def self.tokenize(query_string)
	run_lexer(query_string)
end

# Replace any escaped unicode or whitespace with the _actual_ characters
# To avoid allocating more strings, this modifies the string passed into it
def self.replace_escaped_characters_in_place(raw_string)
	raw_string.gsub!(ESCAPES, ESCAPES_REPLACE)
	raw_string.gsub!(UTF_8, &UTF_8_REPLACE)
	nil
end

private

class << self
	attr_accessor :_graphql_lexer_trans_keys 
	private :_graphql_lexer_trans_keys, :_graphql_lexer_trans_keys=
end
self._graphql_lexer_trans_keys = [
4, 21, 4, 21, 4, 21, 4, 21, 4, 4, 4, 21, 4, 4, 4, 4, 4, 21, 4, 4, 4, 4, 4, 4, 4, 21, 4, 21, 13, 14, 13, 14, 10, 14, 12, 12, 0, 47, 0, 0, 4, 21, 4, 21, 4, 4, 4, 4, 4, 4, 4, 21, 4, 4, 4, 4, 1, 1, 13, 14, 10, 27, 13, 14, 10, 27, 10, 27, 12, 12, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_char_class 
	private :_graphql_lexer_char_class, :_graphql_lexer_char_class=
end
self._graphql_lexer_char_class = [
0, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 3, 4, 5, 6, 2, 7, 2, 8, 9, 2, 10, 0, 11, 12, 2, 13, 14, 14, 14, 14, 14, 14, 14, 14, 14, 15, 2, 2, 16, 2, 2, 17, 18, 18, 18, 18, 19, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 18, 20, 21, 22, 2, 18, 2, 23, 24, 25, 26, 27, 28, 29, 30, 31, 18, 18, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 18, 43, 44, 18, 45, 46, 47, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_offsets 
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
0, 18, 36, 54, 72, 73, 91, 92, 93, 111, 112, 113, 114, 132, 150, 152, 154, 159, 160, 208, 209, 227, 245, 246, 247, 248, 266, 267, 268, 269, 271, 289, 291, 309, 327, 328, 360, 392, 424, 456, 488, 520, 552, 584, 616, 648, 680, 712, 744, 776, 808, 840, 872, 904, 936, 968, 1000, 1032, 1064, 1096, 1128, 1160, 1192, 1224, 1256, 1288, 1320, 1352, 1384, 1416, 1448, 1480, 1512, 1544, 1576, 1608, 1640, 1672, 1704, 1736, 1768, 1800, 1832, 1864, 1896, 1928, 1960, 1992, 2024, 2056, 2088, 2120, 2152, 2184, 2216, 2248, 2280, 2312, 2344, 2376, 2408, 2440, 2472, 2504, 2536, 2568, 2600, 2632, 2664, 2696, 2728, 2760, 2792, 2824, 2856, 2888, 2920, 2952, 2984, 3016, 3048, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 7, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 9, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 11, 12, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 13, 14, 15, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 16, 17, 14, 18, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 19, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 20, 20, 22, 22, 23, 23, 0, 20, 20, 25, 27, 28, 26, 29, 30, 31, 32, 33, 34, 35, 26, 36, 37, 38, 39, 40, 41, 42, 43, 43, 44, 26, 45, 43, 43, 43, 46, 47, 48, 43, 43, 49, 43, 50, 51, 52, 43, 53, 43, 54, 55, 56, 43, 43, 43, 57, 58, 59, 27, 62, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 64, 66, 67, 19, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 8, 68, 14, 69, 38, 39, 23, 23, 71, 20, 20, 70, 70, 70, 70, 72, 70, 70, 70, 70, 70, 70, 70, 72, 20, 20, 23, 23, 73, 22, 22, 73, 73, 73, 73, 72, 73, 73, 73, 73, 73, 73, 73, 72, 23, 23, 71, 39, 39, 70, 70, 70, 70, 72, 70, 70, 70, 70, 70, 70, 70, 72, 74, 43, 43, 0, 0, 0, 43, 43, 0, 0, 0, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 76, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 77, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 78, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 79, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 80, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 81, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 82, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 83, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 84, 43, 43, 43, 43, 43, 43, 43, 43, 85, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 86, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 87, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 88, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 89, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 90, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 91, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 92, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 93, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 94, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 95, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 96, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 97, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 98, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 99, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 100, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 101, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 102, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 103, 104, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 105, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 106, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 107, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 108, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 109, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 110, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 111, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 112, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 113, 43, 43, 43, 114, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 115, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 116, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 117, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 118, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 119, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 120, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 121, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 122, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 123, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 124, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 125, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 126, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 127, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 128, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 129, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 130, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 131, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 132, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 133, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 134, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 135, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 136, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 137, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 138, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 139, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 140, 43, 43, 43, 43, 43, 43, 141, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 142, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 143, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 144, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 145, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 146, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 147, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 148, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 149, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 150, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 151, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 152, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 153, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 154, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 155, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 156, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 157, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 158, 43, 43, 43, 43, 43, 159, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 160, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 161, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 162, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 163, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 164, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 165, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 166, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 75, 75, 75, 43, 43, 75, 75, 75, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 167, 43, 43, 43, 43, 43, 43, 43, 43, 43, 43, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 1, 6, 6, 10, 6, 0, 0, 6, 10, 10, 10, 6, 6, 0, 21, 0, 24, 26, 60, 1, 1, 63, 65, 65, 6, 65, 65, 31, 61, 70, 73, 73, 70, 61, 0, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 75, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
18, 0, 18, 1, 21, 18, 3, 12, 8, 4, 5, 11, 6, 7, 23, 9, 10, 25, 13, 26, 31, 18, 32, 14, 18, 18, 18, 19, 18, 18, 20, 28, 18, 18, 18, 18, 29, 34, 30, 33, 18, 18, 18, 35, 18, 18, 36, 44, 51, 61, 79, 86, 89, 90, 94, 112, 117, 18, 18, 18, 18, 18, 22, 18, 2, 18, 24, 18, 27, 18, 18, 15, 16, 18, 17, 18, 37, 38, 39, 40, 41, 42, 43, 35, 45, 47, 46, 35, 48, 49, 50, 35, 52, 55, 53, 54, 35, 56, 57, 58, 59, 60, 35, 62, 70, 63, 64, 65, 66, 67, 68, 69, 35, 71, 73, 72, 35, 74, 75, 76, 77, 78, 35, 80, 81, 82, 83, 84, 85, 35, 87, 88, 35, 35, 91, 92, 93, 35, 95, 102, 96, 99, 97, 98, 35, 100, 101, 35, 103, 104, 105, 106, 107, 108, 109, 110, 111, 35, 113, 115, 114, 35, 116, 35, 118, 119, 120, 35, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 3, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, 6, 7, 0, 8, 9, 12, 0, 13, 14, 15, 0, 16, 17, 18, 19, 0, 20, 21, 21, 22, 23, 24, 25, 26, 27, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 28, 29, 30, 31, 32, 3, 33, 0, 34, 0, 35, 0, 36, 37, 0, 0, 38, 0, 39, 0, 0, 0, 0, 0, 0, 0, 40, 0, 0, 0, 41, 0, 0, 0, 42, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 0, 0, 0, 45, 0, 0, 0, 46, 0, 0, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0, 48, 0, 0, 49, 50, 0, 0, 0, 51, 0, 0, 0, 0, 0, 0, 52, 0, 0, 53, 0, 0, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0, 55, 0, 56, 0, 0, 0, 57, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 1, 6, 1, 1, 1, 1, 1, 1, 1, 1, 1, 6, 6, 1, 22, 1, 25, 0, 61, 62, 64, 64, 66, 66, 66, 66, 66, 70, 62, 71, 74, 74, 71, 62, 1, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 76, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_targs 
	private :_graphql_lexer_nfa_targs, :_graphql_lexer_nfa_targs=
end
self._graphql_lexer_nfa_targs = [
0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_offsets 
	private :_graphql_lexer_nfa_offsets, :_graphql_lexer_nfa_offsets=
end
self._graphql_lexer_nfa_offsets = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_push_actions 
	private :_graphql_lexer_nfa_push_actions, :_graphql_lexer_nfa_push_actions=
end
self._graphql_lexer_nfa_push_actions = [
0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_nfa_pop_trans 
	private :_graphql_lexer_nfa_pop_trans, :_graphql_lexer_nfa_pop_trans=
end
self._graphql_lexer_nfa_pop_trans = [
0, 0 , 
]

class << self
	attr_accessor :graphql_lexer_start 
end
self.graphql_lexer_start  = 18;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 18;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = -1;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 18;

def self.run_lexer(query_string)
	data = query_string.unpack("c*")
	eof = data.length
	
	# Since `Lexer` is a module, store all lexer state
	# in this local variable:
	meta = {
	line: 1,
	col: 1,
	data: data,
	tokens: [],
	previous_token: nil,
	}
	
	p ||= 0
	pe ||= data.length
	
	begin
		cs = graphql_lexer_start;
		ts = 0;
		te = 0;
		act = 0;
		
	end
	begin
		_trans = 0;
		_have = 0;
		_cont = 1;
		_keys = 0;
		_inds = 0;
		while ( _cont == 1  )
			begin
				_have = 0;
				if ( p == pe  )
					begin
						if ( p == eof  )
							begin
								if ( _graphql_lexer_eof_trans[cs] > 0  )
									begin
										_trans = _graphql_lexer_eof_trans[cs] - 1;
										_have = 1;
										
									end
									
								end
								if ( _have == 0  )
									begin
									
									end
									
								end
								
							end
							
						end
						if ( _have == 0  )
							_cont = 0;
							
						end
						
					end
					
				end
				if ( _cont == 1  )
					begin
						if ( _have == 0  )
							begin
								case  _graphql_lexer_from_state_actions[cs]  
								when -2 then
								begin
								end
								when 11  then
								begin
									begin
										begin
											ts = p;
											
										end
										
									end
									
									
								end
							end
							_keys = (cs<<1) ;
							_inds = _graphql_lexer_index_offsets[cs] ;
							if ( ( data[p ].ord) <= 125 && ( data[p ].ord) >= 9  )
								begin
									_ic = _graphql_lexer_char_class[( data[p ].ord) - 9];
									if ( _ic <= _graphql_lexer_trans_keys[_keys+1 ]&& _ic >= _graphql_lexer_trans_keys[_keys ] )
										_trans = _graphql_lexer_indicies[_inds + ( _ic - _graphql_lexer_trans_keys[_keys ])  ];
										
										else
										_trans = _graphql_lexer_index_defaults[cs];
										
									end
									
								end
								
								else
								begin
									_trans = _graphql_lexer_index_defaults[cs];
									
								end
								
							end
							
						end
						
					end
					if ( _cont == 1  )
						begin
							cs = _graphql_lexer_cond_targs[_trans];
							case  _graphql_lexer_cond_actions[_trans]  
							when -2 then
							begin
							end
							when 20  then
							begin
								begin
									begin
										te = p+1;
										
									end
									
								end
								
							end
							when 30  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RCURLY, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 28  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:LCURLY, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 19  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RPAREN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 18  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:LPAREN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 27  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RBRACKET, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 26  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:LBRACKET, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 22  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:COLON, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 2  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit_string(ts, te, meta, block: false) 
										end
										
									end
									
								end
								
							end
							when 35  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit_string(ts, te, meta, block: true) 
										end
										
									end
									
								end
								
							end
							when 16  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:VAR_SIGN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 24  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:DIR_SIGN, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 9  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:ELLIPSIS, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 23  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:EQUALS, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 14  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:BANG, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 29  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:PIPE, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 17  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:AMP, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 13  then
							begin
								begin
									begin
										te = p+1;
										begin
											meta[:line] += 1
											meta[:col] = 1
											
										end
										
									end
									
								end
								
							end
							when 12  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 37  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:INT, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 38  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:FLOAT, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 33  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit_string(ts, te, meta, block: false) 
										end
										
									end
									
								end
								
							end
							when 34  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit_string(ts, te, meta, block: true) 
										end
										
									end
									
								end
								
							end
							when 39  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:IDENTIFIER, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 36  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											record_comment(ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 31  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											meta[:col] += te - ts 
										end
										
									end
									
								end
								
							end
							when 32  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 6  then
							begin
								begin
									begin
										p = ((te))-1;
										begin
											emit(:INT, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 4  then
							begin
								begin
									begin
										p = ((te))-1;
										begin
											emit_string(ts, te, meta, block: false) 
										end
										
									end
									
								end
								
							end
							when 8  then
							begin
								begin
									begin
										p = ((te))-1;
										begin
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 1  then
							begin
								begin
									begin
										case  act  
										when -2 then
										begin
										end
										when 1  then
										begin
											p = ((te))-1;
											begin
												emit(:INT, ts, te, meta) 
											end
											
										end
										when 2  then
										begin
											p = ((te))-1;
											begin
												emit(:FLOAT, ts, te, meta) 
											end
											
										end
										when 3  then
										begin
											p = ((te))-1;
											begin
												emit(:ON, ts, te, meta) 
											end
											
										end
										when 4  then
										begin
											p = ((te))-1;
											begin
												emit(:FRAGMENT, ts, te, meta) 
											end
											
										end
										when 5  then
										begin
											p = ((te))-1;
											begin
												emit(:TRUE, ts, te, meta) 
											end
											
										end
										when 6  then
										begin
											p = ((te))-1;
											begin
												emit(:FALSE, ts, te, meta) 
											end
											
										end
										when 7  then
										begin
											p = ((te))-1;
											begin
												emit(:NULL, ts, te, meta) 
											end
											
										end
										when 8  then
										begin
											p = ((te))-1;
											begin
												emit(:QUERY, ts, te, meta) 
											end
											
										end
										when 9  then
										begin
											p = ((te))-1;
											begin
												emit(:MUTATION, ts, te, meta) 
											end
											
										end
										when 10  then
										begin
											p = ((te))-1;
											begin
												emit(:SUBSCRIPTION, ts, te, meta) 
											end
											
										end
										when 11  then
										begin
											p = ((te))-1;
											begin
												emit(:SCHEMA, ts, te, meta) 
											end
											
										end
										when 12  then
										begin
											p = ((te))-1;
											begin
												emit(:SCALAR, ts, te, meta) 
											end
											
										end
										when 13  then
										begin
											p = ((te))-1;
											begin
												emit(:TYPE, ts, te, meta) 
											end
											
										end
										when 14  then
										begin
											p = ((te))-1;
											begin
												emit(:EXTEND, ts, te, meta) 
											end
											
										end
										when 15  then
										begin
											p = ((te))-1;
											begin
												emit(:IMPLEMENTS, ts, te, meta) 
											end
											
										end
										when 16  then
										begin
											p = ((te))-1;
											begin
												emit(:INTERFACE, ts, te, meta) 
											end
											
										end
										when 17  then
										begin
											p = ((te))-1;
											begin
												emit(:UNION, ts, te, meta) 
											end
											
										end
										when 18  then
										begin
											p = ((te))-1;
											begin
												emit(:ENUM, ts, te, meta) 
											end
											
										end
										when 19  then
										begin
											p = ((te))-1;
											begin
												emit(:INPUT, ts, te, meta) 
											end
											
										end
										when 20  then
										begin
											p = ((te))-1;
											begin
												emit(:DIRECTIVE, ts, te, meta) 
											end
											
										end
										when 28  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts, te, meta, block: false) 
											end
											
										end
										when 29  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts, te, meta, block: true) 
											end
											
										end
										when 37  then
										begin
											p = ((te))-1;
											begin
												emit(:IDENTIFIER, ts, te, meta) 
											end
											
										end
										when 41  then
										begin
											p = ((te))-1;
											begin
												emit(:UNKNOWN_CHAR, ts, te, meta) 
											end
											
											
										end
									end
									
								end
								
								
							end
							
						end
						when 21  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 1;
									
								end
								
							end
							
						end
						when 7  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 2;
									
								end
								
							end
							
						end
						when 50  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 3;
									
								end
								
							end
							
						end
						when 44  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 4;
									
								end
								
							end
							
						end
						when 55  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 5;
									
								end
								
							end
							
						end
						when 43  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 6;
									
								end
								
							end
							
						end
						when 49  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 7;
									
								end
								
							end
							
						end
						when 51  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 8;
									
								end
								
							end
							
						end
						when 48  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 9;
									
								end
								
							end
							
						end
						when 54  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 10;
									
								end
								
							end
							
						end
						when 53  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 11;
									
								end
								
							end
							
						end
						when 52  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 12;
									
								end
								
							end
							
						end
						when 56  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 13;
									
								end
								
							end
							
						end
						when 42  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 14;
									
								end
								
							end
							
						end
						when 45  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 15;
									
								end
								
							end
							
						end
						when 47  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 16;
									
								end
								
							end
							
						end
						when 57  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 17;
									
								end
								
							end
							
						end
						when 41  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 18;
									
								end
								
							end
							
						end
						when 46  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 19;
									
								end
								
							end
							
						end
						when 40  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 20;
									
								end
								
							end
							
						end
						when 3  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 28;
									
								end
								
							end
							
						end
						when 5  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 29;
									
								end
								
							end
							
						end
						when 25  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 37;
									
								end
								
							end
							
						end
						when 15  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 41;
									
								end
								
							end
							
							
						end
					end
					case  _graphql_lexer_to_state_actions[cs]  
					when -2 then
					begin
					end
					when 10  then
					begin
						begin
							begin
								ts = 0;
								
							end
							
						end
						
						
					end
				end
				if ( _cont == 1  )
					p += 1;
					
				end
				
			end
			
		end
		
	end
	
end

end

end

end
meta[:tokens]
end

def self.record_comment(ts, te, meta)
token = GraphQL::Language::Token.new(
name: :COMMENT,
value: meta[:data][ts...te].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING),
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)

meta[:previous_token] = token

meta[:col] += te - ts
end

def self.emit(token_name, ts, te, meta)
meta[:tokens] << token = GraphQL::Language::Token.new(
name: token_name,
value: meta[:data][ts...te].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING),
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
meta[:previous_token] = token
# Bump the column counter for the next token
meta[:col] += te - ts
end

ESCAPES = /\\["\\\/bfnrt]/
ESCAPES_REPLACE = {
'\\"' => '"',
"\\\\" => "\\",
"\\/" => '/',
"\\b" => "\b",
"\\f" => "\f",
"\\n" => "\n",
"\\r" => "\r",
"\\t" => "\t",
}

UTF_8 = /\\u[\dAa-f]{4}/i
UTF_8_REPLACE = ->(m) { [m[-4..-1].to_i(16)].pack('U'.freeze) }

VALID_STRING = /\A(?:[^\\]|#{ESCAPES}|#{UTF_8})*\z/o

PACK_DIRECTIVE = "c*"
UTF_8_ENCODING = "UTF-8"

def self.emit_string(ts, te, meta, block:)
quotes_length = block ? 3 : 1
ts += quotes_length
value = meta[:data][ts...te - quotes_length].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING)
if block
value = GraphQL::Language::BlockString.trim_whitespace(value)
end
if value !~ VALID_STRING
meta[:tokens] << token = GraphQL::Language::Token.new(
name: :BAD_UNICODE_ESCAPE,
value: value,
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
else
replace_escaped_characters_in_place(value)

meta[:tokens] << token = GraphQL::Language::Token.new(
name: :STRING,
value: value,
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
end

meta[:previous_token] = token
meta[:col] += te - ts
end
end
end
end
