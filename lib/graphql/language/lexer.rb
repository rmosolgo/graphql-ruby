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
4, 21, 1, 0, 4, 21, 4, 21, 4, 21, 4, 21, 4, 21, 21, 21, 13, 14, 13, 14, 10, 14, 12, 12, 0, 47, 0, 0, 4, 21, 4, 4, 1, 1, 13, 14, 10, 27, 13, 14, 10, 27, 10, 27, 12, 12, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 0 , 
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
0, 18, 18, 36, 54, 72, 90, 108, 109, 111, 113, 118, 119, 167, 168, 186, 187, 188, 190, 208, 210, 228, 246, 247, 279, 311, 343, 375, 407, 439, 471, 503, 535, 567, 599, 631, 663, 695, 727, 759, 791, 823, 855, 887, 919, 951, 983, 1015, 1047, 1079, 1111, 1143, 1175, 1207, 1239, 1271, 1303, 1335, 1367, 1399, 1431, 1463, 1495, 1527, 1559, 1591, 1623, 1655, 1687, 1719, 1751, 1783, 1815, 1847, 1879, 1911, 1943, 1975, 2007, 2039, 2071, 2103, 2135, 2167, 2199, 2231, 2263, 2295, 2327, 2359, 2391, 2423, 2455, 2487, 2519, 2551, 2583, 2615, 2647, 2679, 2711, 2743, 2775, 2807, 2839, 2871, 2903, 2935, 2967, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 8, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 9, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 11, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 7, 13, 13, 15, 15, 16, 16, 12, 13, 13, 17, 19, 20, 18, 21, 22, 23, 24, 25, 26, 27, 18, 28, 29, 30, 31, 32, 33, 34, 35, 35, 36, 18, 37, 35, 35, 35, 38, 39, 40, 35, 35, 41, 35, 42, 43, 44, 35, 45, 35, 46, 47, 48, 35, 35, 35, 49, 50, 51, 19, 54, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 5, 56, 30, 31, 16, 16, 58, 13, 13, 57, 57, 57, 57, 59, 57, 57, 57, 57, 57, 57, 57, 59, 13, 13, 16, 16, 60, 15, 15, 60, 60, 60, 60, 59, 60, 60, 60, 60, 60, 60, 60, 59, 16, 16, 58, 31, 31, 57, 57, 57, 57, 59, 57, 57, 57, 57, 57, 57, 57, 59, 61, 35, 35, 12, 12, 12, 35, 35, 12, 12, 12, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 63, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 64, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 65, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 66, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 67, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 68, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 69, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 70, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 71, 35, 35, 35, 35, 35, 35, 35, 35, 72, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 73, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 74, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 75, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 76, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 77, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 78, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 79, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 80, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 81, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 82, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 83, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 84, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 85, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 86, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 87, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 88, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 89, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 90, 91, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 92, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 93, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 94, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 95, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 96, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 97, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 98, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 99, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 100, 35, 35, 35, 101, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 102, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 103, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 104, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 105, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 106, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 107, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 108, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 109, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 110, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 111, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 112, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 113, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 114, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 115, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 116, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 117, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 118, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 119, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 120, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 121, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 122, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 123, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 124, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 125, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 126, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 127, 35, 35, 35, 35, 35, 35, 128, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 129, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 130, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 131, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 132, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 133, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 134, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 135, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 136, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 137, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 138, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 139, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 140, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 141, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 142, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 143, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 144, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 145, 35, 35, 35, 35, 35, 146, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 147, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 148, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 149, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 150, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 151, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 152, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 153, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 62, 62, 62, 35, 35, 62, 62, 62, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 154, 35, 35, 35, 35, 35, 35, 35, 35, 35, 35, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 1, 5, 5, 5, 5, 5, 5, 12, 14, 12, 0, 18, 52, 1, 55, 23, 53, 57, 60, 60, 57, 53, 12, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 62, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
12, 0, 12, 1, 12, 2, 3, 5, 4, 12, 6, 7, 12, 19, 12, 20, 8, 12, 12, 13, 12, 12, 14, 16, 12, 12, 12, 12, 17, 22, 18, 21, 12, 12, 12, 23, 12, 12, 24, 32, 39, 49, 67, 74, 77, 78, 82, 100, 105, 12, 12, 12, 12, 12, 15, 12, 12, 12, 9, 10, 12, 11, 12, 25, 26, 27, 28, 29, 30, 31, 23, 33, 35, 34, 23, 36, 37, 38, 23, 40, 43, 41, 42, 23, 44, 45, 46, 47, 48, 23, 50, 58, 51, 52, 53, 54, 55, 56, 57, 23, 59, 61, 60, 23, 62, 63, 64, 65, 66, 23, 68, 69, 70, 71, 72, 73, 23, 75, 76, 23, 23, 79, 80, 81, 23, 83, 90, 84, 87, 85, 86, 23, 88, 89, 23, 91, 92, 93, 94, 95, 96, 97, 98, 99, 23, 101, 103, 102, 23, 104, 23, 106, 107, 108, 23, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 3, 0, 0, 0, 0, 4, 0, 0, 5, 0, 6, 7, 0, 8, 11, 0, 12, 13, 14, 0, 15, 16, 17, 18, 0, 14, 19, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 28, 29, 30, 14, 31, 32, 33, 0, 0, 34, 0, 35, 0, 0, 0, 0, 0, 0, 0, 36, 0, 0, 0, 37, 0, 0, 0, 38, 0, 0, 0, 0, 39, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 0, 0, 0, 42, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 44, 0, 0, 45, 46, 0, 0, 0, 47, 0, 0, 0, 0, 0, 0, 48, 0, 0, 49, 0, 0, 0, 0, 0, 0, 0, 0, 0, 50, 0, 0, 0, 51, 0, 52, 0, 0, 0, 53, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 1, 5, 5, 5, 5, 5, 5, 13, 15, 13, 1, 0, 53, 54, 56, 57, 54, 58, 61, 61, 58, 54, 13, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 0 , 
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
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
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
self.graphql_lexer_start  = 12;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 12;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = -1;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 12;

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
							when 14  then
							begin
								begin
									begin
										te = p+1;
										
									end
									
								end
								
							end
							when 28  then
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
							when 26  then
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
							when 25  then
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
							when 24  then
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
							when 20  then
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
							when 4  then
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
							when 22  then
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
							when 21  then
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
							when 27  then
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
							when 33  then
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
							when 34  then
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
							when 31  then
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
							when 35  then
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
							when 32  then
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
							when 29  then
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
							when 30  then
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
							when 3  then
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
							when 1  then
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
							when 5  then
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
										when 37  then
										begin
											p = ((te))-1;
											begin
												emit(:IDENTIFIER, ts, te, meta) 
											end
											
											
										end
									end
									
								end
								
								
							end
							
						end
						when 19  then
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
						when 46  then
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
						when 40  then
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
						when 51  then
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
						when 39  then
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
						when 45  then
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
						when 47  then
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
						when 44  then
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
						when 50  then
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
						when 49  then
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
						when 48  then
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
						when 52  then
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
						when 38  then
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
						when 41  then
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
						when 43  then
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
						when 53  then
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
						when 37  then
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
						when 42  then
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
						when 36  then
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
						when 23  then
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
meta[:tokens] << token = GraphQL::Language::Token.new(
name: :STRING,
value: value.gsub('\\"""', '"""'),
line: meta[:line],
col: meta[:col],
prev_token: meta[:previous_token],
)
elsif value !~ VALID_STRING
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
