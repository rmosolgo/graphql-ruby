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
4, 21, 4, 21, 4, 21, 4, 4, 4, 21, 4, 4, 4, 4, 4, 21, 4, 4, 4, 4, 4, 4, 13, 14, 13, 14, 10, 14, 12, 12, 0, 47, 0, 0, 4, 21, 4, 21, 4, 4, 4, 4, 4, 4, 4, 21, 4, 4, 4, 4, 1, 1, 13, 14, 10, 27, 13, 14, 10, 27, 10, 27, 12, 12, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 0 , 
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
0, 18, 36, 54, 55, 73, 74, 75, 93, 94, 95, 96, 98, 100, 105, 106, 154, 155, 173, 191, 192, 193, 194, 212, 213, 214, 215, 217, 235, 237, 255, 273, 274, 306, 338, 370, 402, 434, 466, 498, 530, 562, 594, 626, 658, 690, 722, 754, 786, 818, 850, 882, 914, 946, 978, 1010, 1042, 1074, 1106, 1138, 1170, 1202, 1234, 1266, 1298, 1330, 1362, 1394, 1426, 1458, 1490, 1522, 1554, 1586, 1618, 1650, 1682, 1714, 1746, 1778, 1810, 1842, 1874, 1906, 1938, 1970, 2002, 2034, 2066, 2098, 2130, 2162, 2194, 2226, 2258, 2290, 2322, 2354, 2386, 2418, 2450, 2482, 2514, 2546, 2578, 2610, 2642, 2674, 2706, 2738, 2770, 2802, 2834, 2866, 2898, 2930, 2962, 2994, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 9, 10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 11, 12, 13, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 14, 15, 12, 16, 16, 18, 18, 19, 19, 0, 16, 16, 21, 23, 24, 22, 25, 26, 27, 28, 29, 30, 31, 22, 32, 33, 34, 35, 36, 37, 38, 39, 39, 40, 22, 41, 39, 39, 39, 42, 43, 44, 39, 39, 45, 39, 46, 47, 48, 39, 49, 39, 50, 51, 52, 39, 39, 39, 53, 54, 55, 23, 58, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 5, 61, 62, 63, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 64, 12, 65, 34, 35, 19, 19, 67, 16, 16, 66, 66, 66, 66, 68, 66, 66, 66, 66, 66, 66, 66, 68, 16, 16, 19, 19, 69, 18, 18, 69, 69, 69, 69, 68, 69, 69, 69, 69, 69, 69, 69, 68, 19, 19, 67, 35, 35, 66, 66, 66, 66, 68, 66, 66, 66, 66, 66, 66, 66, 68, 70, 39, 39, 0, 0, 0, 39, 39, 0, 0, 0, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 72, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 73, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 74, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 75, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 76, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 77, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 78, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 79, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 80, 39, 39, 39, 39, 39, 39, 39, 39, 81, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 82, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 83, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 84, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 85, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 86, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 87, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 88, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 89, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 90, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 91, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 92, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 93, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 94, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 95, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 96, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 97, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 98, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 99, 100, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 101, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 102, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 103, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 104, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 105, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 106, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 107, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 108, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 109, 39, 39, 39, 110, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 111, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 112, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 113, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 114, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 115, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 116, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 117, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 118, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 119, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 120, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 121, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 122, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 123, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 124, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 125, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 126, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 127, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 128, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 129, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 130, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 131, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 132, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 133, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 134, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 135, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 136, 39, 39, 39, 39, 39, 39, 137, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 138, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 139, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 140, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 141, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 142, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 143, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 144, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 145, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 146, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 147, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 148, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 149, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 150, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 151, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 152, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 153, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 154, 39, 39, 39, 39, 39, 155, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 156, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 157, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 158, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 159, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 160, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 161, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 162, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 71, 71, 71, 39, 39, 71, 71, 71, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 163, 39, 39, 39, 39, 39, 39, 39, 39, 39, 39, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 1, 5, 8, 5, 0, 0, 5, 8, 8, 8, 0, 17, 0, 20, 22, 56, 1, 1, 59, 60, 60, 5, 60, 60, 27, 57, 66, 69, 69, 66, 57, 0, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 71, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
15, 0, 15, 1, 18, 2, 3, 7, 4, 10, 5, 6, 20, 8, 9, 22, 28, 15, 29, 11, 15, 15, 15, 16, 15, 15, 17, 25, 15, 15, 15, 15, 26, 31, 27, 30, 15, 15, 15, 32, 15, 15, 33, 41, 48, 58, 76, 83, 86, 87, 91, 109, 114, 15, 15, 15, 15, 15, 19, 15, 15, 21, 15, 23, 24, 15, 15, 12, 13, 15, 14, 15, 34, 35, 36, 37, 38, 39, 40, 32, 42, 44, 43, 32, 45, 46, 47, 32, 49, 52, 50, 51, 32, 53, 54, 55, 56, 57, 32, 59, 67, 60, 61, 62, 63, 64, 65, 66, 32, 68, 70, 69, 32, 71, 72, 73, 74, 75, 32, 77, 78, 79, 80, 81, 82, 32, 84, 85, 32, 32, 88, 89, 90, 32, 92, 99, 93, 96, 94, 95, 32, 97, 98, 32, 100, 101, 102, 103, 104, 105, 106, 107, 108, 32, 110, 112, 111, 32, 113, 32, 115, 116, 117, 32, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 6, 0, 7, 8, 11, 0, 12, 13, 14, 0, 15, 16, 17, 18, 0, 19, 20, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 28, 29, 30, 31, 3, 32, 33, 0, 34, 0, 0, 35, 36, 0, 0, 37, 0, 38, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 40, 0, 0, 0, 41, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 45, 0, 0, 0, 0, 0, 46, 0, 0, 0, 0, 0, 0, 47, 0, 0, 48, 49, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 51, 0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 0, 0, 0, 54, 0, 55, 0, 0, 0, 56, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 18, 1, 21, 0, 57, 58, 60, 60, 61, 61, 61, 61, 61, 66, 58, 67, 70, 70, 67, 58, 1, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 72, 0 , 
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
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
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
self.graphql_lexer_start  = 15;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 15;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = -1;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 15;

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
								when 10  then
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
							when 19  then
							begin
								begin
									begin
										te = p+1;
										
									end
									
								end
								
							end
							when 29  then
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
							when 27  then
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
							when 18  then
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
							when 17  then
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
							when 26  then
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
							when 25  then
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
							when 21  then
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
							when 34  then
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
							when 15  then
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
							when 23  then
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
							when 8  then
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
							when 22  then
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
							when 13  then
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
							when 28  then
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
							when 16  then
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
							when 12  then
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
							when 11  then
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
							when 36  then
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
							when 37  then
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
							when 32  then
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
							when 33  then
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
							when 38  then
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
							when 35  then
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
							when 30  then
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
							when 31  then
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
							when 5  then
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
							when 7  then
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
						when 20  then
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
						when 6  then
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
						when 49  then
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
						when 43  then
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
						when 54  then
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
						when 42  then
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
						when 48  then
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
						when 50  then
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
						when 47  then
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
						when 53  then
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
						when 52  then
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
						when 51  then
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
						when 55  then
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
						when 41  then
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
						when 44  then
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
						when 46  then
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
						when 56  then
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
						when 40  then
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
						when 45  then
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
						when 39  then
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
						when 4  then
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
						when 24  then
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
						when 14  then
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
					when 9  then
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
