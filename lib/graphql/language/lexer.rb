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
1, 0, 13, 14, 13, 14, 10, 14, 12, 12, 0, 47, 0, 0, 4, 21, 4, 21, 4, 4, 4, 21, 4, 21, 4, 21, 4, 21, 4, 21, 21, 21, 1, 1, 13, 14, 10, 27, 13, 14, 10, 27, 10, 27, 12, 12, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 0 , 
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
0, 0, 2, 4, 9, 10, 58, 59, 77, 95, 96, 114, 132, 150, 168, 186, 187, 188, 190, 208, 210, 228, 246, 247, 279, 311, 343, 375, 407, 439, 471, 503, 535, 567, 599, 631, 663, 695, 727, 759, 791, 823, 855, 887, 919, 951, 983, 1015, 1047, 1079, 1111, 1143, 1175, 1207, 1239, 1271, 1303, 1335, 1367, 1399, 1431, 1463, 1495, 1527, 1559, 1591, 1623, 1655, 1687, 1719, 1751, 1783, 1815, 1847, 1879, 1911, 1943, 1975, 2007, 2039, 2071, 2103, 2135, 2167, 2199, 2231, 2263, 2295, 2327, 2359, 2391, 2423, 2455, 2487, 2519, 2551, 2583, 2615, 2647, 2679, 2711, 2743, 2775, 2807, 2839, 2871, 2903, 2935, 2967, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
3, 3, 5, 5, 6, 6, 2, 3, 3, 8, 10, 11, 9, 12, 13, 14, 15, 16, 17, 18, 9, 19, 20, 21, 22, 23, 24, 25, 26, 26, 27, 9, 28, 26, 26, 26, 29, 30, 31, 26, 26, 32, 26, 33, 34, 35, 26, 36, 26, 37, 38, 39, 26, 26, 26, 40, 41, 42, 10, 45, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 46, 47, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 46, 49, 51, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 52, 53, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 52, 54, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 52, 55, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 52, 56, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 49, 52, 52, 57, 21, 22, 6, 6, 60, 3, 3, 59, 59, 59, 59, 61, 59, 59, 59, 59, 59, 59, 59, 61, 3, 3, 6, 6, 62, 5, 5, 62, 62, 62, 62, 61, 62, 62, 62, 62, 62, 62, 62, 61, 6, 6, 60, 22, 22, 59, 59, 59, 59, 61, 59, 59, 59, 59, 59, 59, 59, 61, 63, 26, 26, 2, 2, 2, 26, 26, 2, 2, 2, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 65, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 66, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 67, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 68, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 69, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 70, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 71, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 72, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 73, 26, 26, 26, 26, 26, 26, 26, 26, 74, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 75, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 76, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 77, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 78, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 79, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 80, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 81, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 82, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 83, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 84, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 85, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 86, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 87, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 88, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 89, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 90, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 91, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 92, 93, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 94, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 95, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 96, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 97, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 98, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 99, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 100, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 101, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 102, 26, 26, 26, 103, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 104, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 105, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 106, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 107, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 108, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 109, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 110, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 111, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 112, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 113, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 114, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 115, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 116, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 117, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 118, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 119, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 120, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 121, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 122, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 123, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 124, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 125, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 126, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 127, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 128, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 129, 26, 26, 26, 26, 26, 26, 130, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 131, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 132, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 133, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 134, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 135, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 136, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 137, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 138, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 139, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 140, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 141, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 142, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 143, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 144, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 145, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 146, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 147, 26, 26, 26, 26, 26, 148, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 149, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 150, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 151, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 152, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 153, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 154, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 155, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 64, 64, 64, 26, 26, 64, 64, 64, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 156, 26, 26, 26, 26, 26, 26, 26, 26, 26, 26, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 2, 4, 2, 7, 9, 43, 1, 1, 48, 49, 49, 49, 49, 49, 49, 14, 58, 59, 62, 62, 59, 58, 2, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
5, 8, 5, 19, 5, 20, 1, 5, 5, 5, 6, 5, 5, 7, 16, 5, 5, 5, 5, 17, 22, 18, 21, 5, 5, 5, 23, 5, 5, 24, 32, 39, 49, 67, 74, 77, 78, 82, 100, 105, 5, 5, 5, 5, 5, 9, 0, 5, 5, 10, 5, 11, 13, 12, 5, 14, 15, 5, 5, 5, 2, 3, 5, 4, 5, 25, 26, 27, 28, 29, 30, 31, 23, 33, 35, 34, 23, 36, 37, 38, 23, 40, 43, 41, 42, 23, 44, 45, 46, 47, 48, 23, 50, 58, 51, 52, 53, 54, 55, 56, 57, 23, 59, 61, 60, 23, 62, 63, 64, 65, 66, 23, 68, 69, 70, 71, 72, 73, 23, 75, 76, 23, 23, 79, 80, 81, 23, 83, 90, 84, 87, 85, 86, 23, 88, 89, 23, 91, 92, 93, 94, 95, 96, 97, 98, 99, 23, 101, 103, 102, 23, 104, 23, 106, 107, 108, 23, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 2, 3, 0, 4, 5, 0, 6, 7, 10, 0, 11, 12, 2, 0, 13, 14, 15, 16, 0, 2, 17, 17, 18, 19, 20, 21, 22, 23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 24, 25, 26, 27, 28, 0, 0, 29, 30, 0, 31, 0, 0, 0, 32, 0, 0, 33, 34, 35, 0, 0, 36, 0, 37, 0, 0, 0, 0, 0, 0, 0, 38, 0, 0, 0, 39, 0, 0, 0, 40, 0, 0, 0, 0, 41, 0, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 0, 0, 0, 0, 43, 0, 0, 0, 44, 0, 0, 0, 0, 0, 45, 0, 0, 0, 0, 0, 0, 46, 0, 0, 47, 48, 0, 0, 0, 49, 0, 0, 0, 0, 0, 0, 50, 0, 0, 51, 0, 0, 0, 0, 0, 0, 0, 0, 0, 52, 0, 0, 0, 53, 0, 54, 0, 0, 0, 55, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 3, 5, 3, 8, 0, 44, 45, 45, 49, 51, 51, 51, 51, 51, 51, 58, 59, 60, 63, 63, 60, 59, 3, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 0 , 
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
self.graphql_lexer_start  = 5;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 5;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = -1;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 5;

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
								when 9  then
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
							when 2  then
							begin
								begin
									begin
										te = p+1;
										
									end
									
								end
								
							end
							when 26  then
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
							when 24  then
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
							when 16  then
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
							when 15  then
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
							when 23  then
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
							when 22  then
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
							when 18  then
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
							when 29  then
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
							when 32  then
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
							when 13  then
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
							when 20  then
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
							when 7  then
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
							when 19  then
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
							when 12  then
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
							when 25  then
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
							when 14  then
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
							when 11  then
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
							when 10  then
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
							when 35  then
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
							when 36  then
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
							when 30  then
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
							when 37  then
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
							when 33  then
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
							when 27  then
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
											emit(:UNMATCHED_BLOCK_STRING, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 28  then
							begin
								begin
									begin
										te = p;
										p = p - 1;
										begin
											emit(:UNMATCHED_QUOTED_STRING, ts, te, meta) 
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
											emit(:UNKNOWN_CHAR, ts, te, meta) 
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
											emit(:INT, ts, te, meta) 
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
											emit(:UNMATCHED_QUOTED_STRING, ts, te, meta) 
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
											emit(:UNKNOWN_CHAR, ts, te, meta) 
										end
										
									end
									
								end
								
							end
							when 3  then
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
						when 17  then
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
						when 5  then
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
						when 48  then
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
						when 42  then
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
						when 53  then
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
						when 41  then
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
						when 47  then
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
						when 49  then
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
						when 46  then
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
						when 52  then
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
						when 51  then
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
						when 50  then
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
						when 54  then
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
						when 40  then
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
						when 43  then
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
						when 45  then
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
						when 55  then
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
						when 39  then
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
						when 44  then
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
						when 38  then
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
						when 21  then
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
					when 8  then
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
