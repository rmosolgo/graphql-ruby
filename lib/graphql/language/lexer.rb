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
4, 20, 4, 20, 12, 13, 12, 13, 9, 13, 11, 11, 0, 45, 0, 0, 4, 20, 1, 1, 12, 13, 9, 26, 12, 13, 9, 26, 9, 26, 11, 11, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 12, 42, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_char_class 
	private :_graphql_lexer_char_class, :_graphql_lexer_char_class=
end
self._graphql_lexer_char_class = [
0, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 3, 4, 5, 6, 2, 2, 2, 7, 8, 2, 9, 0, 10, 11, 2, 12, 13, 13, 13, 13, 13, 13, 13, 13, 13, 14, 2, 2, 15, 2, 2, 16, 17, 17, 17, 17, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 19, 20, 21, 2, 17, 2, 22, 23, 24, 25, 26, 27, 28, 29, 30, 17, 17, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 17, 17, 42, 17, 43, 44, 45, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_offsets 
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
0, 17, 34, 36, 38, 43, 44, 90, 91, 108, 109, 111, 129, 131, 149, 167, 168, 199, 230, 261, 292, 323, 354, 385, 416, 447, 478, 509, 540, 571, 602, 633, 664, 695, 726, 757, 788, 819, 850, 881, 912, 943, 974, 1005, 1036, 1067, 1098, 1129, 1160, 1191, 1222, 1253, 1284, 1315, 1346, 1377, 1408, 1439, 1470, 1501, 1532, 1563, 1594, 1625, 1656, 1687, 1718, 1749, 1780, 1811, 1842, 1873, 1904, 1935, 1966, 1997, 2028, 2059, 2090, 2121, 2152, 2183, 2214, 2245, 2276, 2307, 2338, 2369, 2400, 2431, 2462, 2493, 2524, 2555, 2586, 2617, 2648, 2679, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 5, 5, 7, 7, 8, 8, 0, 5, 5, 10, 12, 13, 11, 14, 15, 16, 17, 18, 19, 11, 20, 21, 22, 23, 24, 25, 26, 27, 27, 28, 11, 29, 27, 27, 27, 30, 31, 32, 27, 27, 33, 27, 34, 35, 36, 27, 37, 27, 38, 39, 40, 27, 27, 41, 42, 43, 12, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 45, 22, 23, 8, 8, 48, 5, 5, 47, 47, 47, 47, 49, 47, 47, 47, 47, 47, 47, 47, 49, 5, 5, 8, 8, 50, 7, 7, 50, 50, 50, 50, 49, 50, 50, 50, 50, 50, 50, 50, 49, 8, 8, 48, 23, 23, 47, 47, 47, 47, 49, 47, 47, 47, 47, 47, 47, 47, 49, 51, 27, 27, 0, 0, 0, 27, 27, 0, 0, 0, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 53, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 54, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 55, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 56, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 57, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 58, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 59, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 60, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 61, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 62, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 63, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 64, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 65, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 66, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 67, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 68, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 69, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 70, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 71, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 72, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 73, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 74, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 75, 76, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 77, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 78, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 79, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 80, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 81, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 82, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 83, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 84, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 85, 27, 27, 27, 86, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 87, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 88, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 89, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 90, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 91, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 92, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 93, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 94, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 95, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 96, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 97, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 98, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 99, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 100, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 101, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 102, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 103, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 104, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 105, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 106, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 107, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 108, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 109, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 110, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 111, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 112, 27, 27, 27, 27, 27, 27, 113, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 114, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 115, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 116, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 117, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 118, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 119, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 120, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 121, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 122, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 123, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 124, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 125, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 126, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 127, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 128, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 129, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 130, 27, 27, 27, 27, 131, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 132, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 133, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 134, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 135, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 136, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 137, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 138, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 52, 52, 52, 27, 27, 52, 52, 52, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 139, 27, 27, 27, 27, 27, 27, 27, 27, 27, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 1, 0, 6, 0, 9, 11, 44, 1, 16, 46, 47, 50, 50, 47, 46, 0, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 52, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
6, 0, 6, 1, 8, 12, 6, 13, 2, 6, 6, 6, 7, 6, 6, 8, 9, 6, 6, 6, 10, 15, 11, 14, 6, 6, 6, 16, 6, 6, 17, 25, 28, 38, 56, 63, 66, 67, 71, 89, 94, 6, 6, 6, 6, 6, 6, 6, 3, 4, 6, 5, 6, 18, 19, 20, 21, 22, 23, 24, 16, 26, 27, 16, 29, 32, 30, 31, 16, 33, 34, 35, 36, 37, 16, 39, 47, 40, 41, 42, 43, 44, 45, 46, 16, 48, 50, 49, 16, 51, 52, 53, 54, 55, 16, 57, 58, 59, 60, 61, 62, 16, 64, 65, 16, 16, 68, 69, 70, 16, 72, 79, 73, 76, 74, 75, 16, 77, 78, 16, 80, 81, 82, 83, 84, 85, 86, 87, 88, 16, 90, 92, 91, 16, 93, 16, 95, 96, 97, 16, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 3, 0, 4, 5, 0, 6, 7, 10, 0, 11, 12, 13, 0, 14, 15, 16, 0, 17, 18, 18, 19, 20, 21, 22, 23, 24, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 25, 26, 27, 28, 29, 30, 31, 0, 0, 32, 0, 33, 0, 0, 0, 0, 0, 0, 0, 34, 0, 0, 35, 0, 0, 0, 0, 36, 0, 0, 0, 0, 0, 37, 0, 0, 0, 0, 0, 0, 0, 0, 0, 38, 0, 0, 0, 39, 0, 0, 0, 0, 0, 40, 0, 0, 0, 0, 0, 0, 41, 0, 0, 42, 43, 0, 0, 0, 44, 0, 0, 0, 0, 0, 0, 45, 0, 0, 46, 0, 0, 0, 0, 0, 0, 0, 0, 0, 47, 0, 0, 0, 48, 0, 49, 0, 0, 0, 50, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 1, 1, 7, 1, 10, 0, 45, 1, 46, 47, 48, 51, 51, 48, 47, 1, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 0 , 
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
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
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
self.graphql_lexer_start  = 6;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 6;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = -1;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 6;

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
							when 17  then
							begin
								begin
									begin
										te = p+1;
										
									end
									
								end
								
							end
							when 27  then
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
							when 25  then
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
							when 24  then
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
							when 23  then
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
							when 19  then
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
											emit_string(ts + 1, te - 1, meta) 
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
											emit(:VAR_SIGN, ts, te, meta) 
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
							when 20  then
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
							when 26  then
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
							when 31  then
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
							when 32  then
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
											emit(:IDENTIFIER, ts, te, meta) 
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
											record_comment(ts, te, meta) 
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
												emit(:IMPLEMENTS, ts, te, meta) 
											end
											
										end
										when 15  then
										begin
											p = ((te))-1;
											begin
												emit(:INTERFACE, ts, te, meta) 
											end
											
										end
										when 16  then
										begin
											p = ((te))-1;
											begin
												emit(:UNION, ts, te, meta) 
											end
											
										end
										when 17  then
										begin
											p = ((te))-1;
											begin
												emit(:ENUM, ts, te, meta) 
											end
											
										end
										when 18  then
										begin
											p = ((te))-1;
											begin
												emit(:INPUT, ts, te, meta) 
											end
											
										end
										when 19  then
										begin
											p = ((te))-1;
											begin
												emit(:DIRECTIVE, ts, te, meta) 
											end
											
										end
										when 27  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts + 1, te - 1, meta) 
											end
											
										end
										when 34  then
										begin
											p = ((te))-1;
											begin
												emit(:IDENTIFIER, ts, te, meta) 
											end
											
										end
										when 38  then
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
						when 18  then
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
						when 43  then
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
						when 37  then
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
						when 48  then
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
						when 36  then
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
						when 42  then
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
						when 44  then
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
						when 41  then
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
						when 47  then
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
						when 46  then
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
						when 45  then
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
						when 49  then
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
						when 40  then
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
						when 50  then
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
						when 35  then
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
						when 34  then
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
						when 3  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 27;
									
								end
								
							end
							
						end
						when 22  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 34;
									
								end
								
							end
							
						end
						when 13  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 38;
									
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

def self.emit_string(ts, te, meta)
value = meta[:data][ts...te].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING)
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
