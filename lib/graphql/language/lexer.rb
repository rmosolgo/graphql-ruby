# frozen_string_literal: true

module GraphQL
module Language
module Lexer
if !String.method_defined?(:match?)
	using GraphQL::StringMatchBackport
end

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
1, 0, 4, 22, 4, 43, 14, 46, 14, 46, 14, 46, 14, 46, 4, 22, 4, 4, 4, 4, 4, 22, 4, 4, 4, 4, 14, 15, 14, 15, 10, 15, 12, 12, 4, 22, 4, 43, 14, 46, 14, 46, 14, 46, 14, 46, 0, 49, 0, 0, 4, 22, 4, 4, 4, 4, 4, 4, 4, 22, 4, 4, 4, 4, 1, 1, 14, 15, 10, 29, 14, 15, 10, 29, 10, 29, 12, 12, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 14, 46, 4, 4, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_char_class 
	private :_graphql_lexer_char_class, :_graphql_lexer_char_class=
end
self._graphql_lexer_char_class = [
0, 1, 2, 2, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 3, 4, 5, 6, 2, 7, 2, 8, 9, 2, 10, 0, 11, 12, 13, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15, 16, 2, 2, 17, 2, 2, 18, 19, 19, 19, 19, 20, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 21, 22, 23, 2, 24, 2, 25, 26, 27, 28, 29, 30, 31, 32, 33, 19, 19, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 19, 45, 46, 19, 47, 48, 49, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_offsets 
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
0, 0, 19, 59, 92, 125, 158, 191, 210, 211, 212, 231, 232, 233, 235, 237, 243, 244, 263, 303, 336, 369, 402, 435, 485, 486, 505, 506, 507, 508, 527, 528, 529, 530, 532, 552, 554, 574, 594, 595, 628, 661, 694, 727, 760, 793, 826, 859, 892, 925, 958, 991, 1024, 1057, 1090, 1123, 1156, 1189, 1222, 1255, 1288, 1321, 1354, 1387, 1420, 1453, 1486, 1519, 1552, 1585, 1618, 1651, 1684, 1717, 1750, 1783, 1816, 1849, 1882, 1915, 1948, 1981, 2014, 2047, 2080, 2113, 2146, 2179, 2212, 2245, 2278, 2311, 2344, 2377, 2410, 2443, 2476, 2509, 2542, 2575, 2608, 2641, 2674, 2707, 2740, 2773, 2806, 2839, 2872, 2905, 2938, 2971, 3004, 3037, 3070, 3103, 3136, 3169, 3202, 3235, 3268, 3301, 3334, 3367, 3400, 3433, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 4, 5, 5, 0, 0, 0, 5, 5, 0, 0, 0, 0, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 0, 0, 0, 6, 6, 0, 0, 0, 0, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 0, 0, 0, 7, 7, 0, 0, 0, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 10, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 11, 12, 13, 14, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 11, 15, 16, 17, 17, 19, 19, 20, 20, 8, 8, 17, 17, 21, 23, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 24, 22, 25, 25, 25, 25, 25, 25, 25, 25, 22, 25, 25, 25, 25, 25, 25, 25, 25, 22, 25, 25, 25, 22, 25, 25, 25, 22, 25, 25, 25, 25, 25, 22, 25, 25, 25, 22, 25, 22, 26, 27, 27, 25, 25, 25, 27, 27, 25, 25, 25, 25, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 25, 25, 25, 28, 28, 25, 25, 25, 25, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 25, 25, 25, 29, 29, 25, 25, 25, 25, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 29, 22, 22, 25, 25, 25, 22, 22, 25, 25, 25, 25, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 31, 32, 30, 33, 34, 35, 36, 37, 38, 39, 30, 40, 41, 30, 42, 43, 44, 45, 46, 47, 47, 48, 30, 49, 47, 47, 47, 47, 50, 51, 52, 47, 47, 53, 47, 54, 55, 56, 47, 57, 47, 58, 59, 60, 47, 47, 47, 61, 62, 63, 31, 66, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 9, 69, 70, 71, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 11, 72, 13, 73, 42, 43, 20, 20, 75, 74, 17, 17, 74, 74, 74, 74, 76, 74, 74, 74, 74, 74, 74, 74, 74, 76, 17, 17, 20, 20, 77, 77, 19, 19, 77, 77, 77, 77, 76, 77, 77, 77, 77, 77, 77, 77, 77, 76, 20, 20, 75, 74, 43, 43, 74, 74, 74, 74, 76, 74, 74, 74, 74, 74, 74, 74, 74, 76, 78, 47, 47, 8, 8, 8, 47, 47, 8, 8, 8, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 80, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 81, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 82, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 83, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 84, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 85, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 86, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 87, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 88, 47, 47, 47, 47, 47, 47, 47, 47, 89, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 90, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 91, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 92, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 93, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 94, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 95, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 96, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 97, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 98, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 99, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 100, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 101, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 102, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 103, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 104, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 105, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 106, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 107, 108, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 109, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 110, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 111, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 112, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 113, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 114, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 115, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 116, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 117, 47, 47, 47, 118, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 119, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 120, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 121, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 122, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 123, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 124, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 125, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 126, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 127, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 128, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 129, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 130, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 131, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 132, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 133, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 134, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 135, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 136, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 137, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 138, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 139, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 140, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 141, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 142, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 143, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 144, 47, 47, 47, 47, 47, 47, 145, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 146, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 147, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 148, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 149, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 150, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 151, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 152, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 153, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 154, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 155, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 156, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 157, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 158, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 159, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 160, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 161, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 162, 47, 47, 47, 47, 47, 163, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 164, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 165, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 166, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 167, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 168, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 169, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 170, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 79, 79, 79, 47, 47, 79, 79, 79, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 171, 47, 47, 47, 47, 47, 47, 47, 47, 47, 47, 22, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
0, 1, 0, 0, 0, 0, 0, 9, 9, 9, 9, 9, 9, 8, 18, 8, 0, 22, 25, 25, 25, 25, 25, 30, 64, 1, 67, 68, 68, 9, 9, 9, 35, 65, 74, 77, 77, 74, 65, 8, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 79, 25, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
23, 1, 23, 2, 3, 4, 5, 6, 23, 7, 8, 10, 9, 27, 11, 12, 29, 35, 23, 36, 13, 23, 17, 125, 18, 0, 19, 20, 21, 22, 23, 24, 23, 23, 25, 32, 23, 23, 23, 23, 33, 38, 34, 37, 23, 23, 23, 39, 23, 23, 40, 48, 55, 65, 83, 90, 93, 94, 98, 116, 121, 23, 23, 23, 23, 23, 26, 23, 23, 28, 23, 30, 31, 23, 23, 14, 15, 23, 16, 23, 41, 42, 43, 44, 45, 46, 47, 39, 49, 51, 50, 39, 52, 53, 54, 39, 56, 59, 57, 58, 39, 60, 61, 62, 63, 64, 39, 66, 74, 67, 68, 69, 70, 71, 72, 73, 39, 75, 77, 76, 39, 78, 79, 80, 81, 82, 39, 84, 85, 86, 87, 88, 89, 39, 91, 92, 39, 39, 95, 96, 97, 39, 99, 106, 100, 103, 101, 102, 39, 104, 105, 39, 107, 108, 109, 110, 111, 112, 113, 114, 115, 39, 117, 119, 118, 39, 120, 39, 122, 123, 124, 39, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 6, 0, 7, 0, 8, 0, 0, 0, 0, 0, 0, 11, 0, 12, 13, 14, 0, 15, 16, 17, 18, 0, 14, 19, 19, 20, 21, 22, 23, 24, 25, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 26, 27, 28, 29, 30, 31, 32, 33, 0, 34, 4, 4, 35, 36, 0, 0, 37, 0, 38, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 40, 0, 0, 0, 41, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 45, 0, 0, 0, 0, 0, 46, 0, 0, 0, 0, 0, 0, 47, 0, 0, 48, 49, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 51, 0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 0, 0, 0, 54, 0, 55, 0, 0, 0, 56, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
0, 1, 1, 1, 1, 1, 1, 9, 9, 9, 9, 9, 9, 9, 19, 9, 1, 0, 0, 0, 0, 0, 0, 0, 65, 66, 68, 69, 69, 69, 69, 69, 74, 66, 75, 78, 78, 75, 66, 9, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 0, 0 , 
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
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
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
self.graphql_lexer_start  = 23;

class << self
	attr_accessor :graphql_lexer_first_final 
end
self.graphql_lexer_first_final  = 23;

class << self
	attr_accessor :graphql_lexer_error 
end
self.graphql_lexer_error  = 0;

class << self
	attr_accessor :graphql_lexer_en_str 
end
self.graphql_lexer_en_str  = 125;

class << self
	attr_accessor :graphql_lexer_en_main 
end
self.graphql_lexer_en_main  = 23;

def self.run_lexer(query_string)
	data = query_string.unpack(PACK_DIRECTIVE)
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
				if ( cs == 0  )
					_cont = 0;
					
				end
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
							when 8  then
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
							when 28  then
							begin
								begin
									begin
										te = p+1;
										begin
											emit(:RCURLY, ts, te, meta, "}") 
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
											emit(:LCURLY, ts, te, meta, "{") 
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
											emit(:RPAREN, ts, te, meta, ")") 
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
											emit(:LPAREN, ts, te, meta, "(")
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
											emit(:RBRACKET, ts, te, meta, "]") 
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
											emit(:LBRACKET, ts, te, meta, "[") 
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
											emit(:COLON, ts, te, meta, ":") 
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
											emit(:VAR_SIGN, ts, te, meta, "$") 
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
											emit(:DIR_SIGN, ts, te, meta, "@") 
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
											emit(:ELLIPSIS, ts, te, meta, "...") 
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
											emit(:EQUALS, ts, te, meta, "=") 
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
											emit(:BANG, ts, te, meta, "!") 
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
											emit(:PIPE, ts, te, meta, "|") 
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
											emit(:AMP, ts, te, meta, "&") 
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
							when 3  then
							begin
								begin
									begin
										case  act  
										when -2 then
										begin
										end
										when 2  then
										begin
											p = ((te))-1;
											begin
												emit(:INT, ts, te, meta) 
											end
											
										end
										when 3  then
										begin
											p = ((te))-1;
											begin
												emit(:FLOAT, ts, te, meta) 
											end
											
										end
										when 4  then
										begin
											p = ((te))-1;
											begin
												emit(:ON, ts, te, meta, "on") 
											end
											
										end
										when 5  then
										begin
											p = ((te))-1;
											begin
												emit(:FRAGMENT, ts, te, meta, "fragment") 
											end
											
										end
										when 6  then
										begin
											p = ((te))-1;
											begin
												emit(:TRUE, ts, te, meta, "true") 
											end
											
										end
										when 7  then
										begin
											p = ((te))-1;
											begin
												emit(:FALSE, ts, te, meta, "false") 
											end
											
										end
										when 8  then
										begin
											p = ((te))-1;
											begin
												emit(:NULL, ts, te, meta, "null") 
											end
											
										end
										when 9  then
										begin
											p = ((te))-1;
											begin
												emit(:QUERY, ts, te, meta, "query") 
											end
											
										end
										when 10  then
										begin
											p = ((te))-1;
											begin
												emit(:MUTATION, ts, te, meta, "mutation") 
											end
											
										end
										when 11  then
										begin
											p = ((te))-1;
											begin
												emit(:SUBSCRIPTION, ts, te, meta, "subscription") 
											end
											
										end
										when 12  then
										begin
											p = ((te))-1;
											begin
												emit(:SCHEMA, ts, te, meta) 
											end
											
										end
										when 13  then
										begin
											p = ((te))-1;
											begin
												emit(:SCALAR, ts, te, meta) 
											end
											
										end
										when 14  then
										begin
											p = ((te))-1;
											begin
												emit(:TYPE, ts, te, meta) 
											end
											
										end
										when 15  then
										begin
											p = ((te))-1;
											begin
												emit(:EXTEND, ts, te, meta) 
											end
											
										end
										when 16  then
										begin
											p = ((te))-1;
											begin
												emit(:IMPLEMENTS, ts, te, meta) 
											end
											
										end
										when 17  then
										begin
											p = ((te))-1;
											begin
												emit(:INTERFACE, ts, te, meta) 
											end
											
										end
										when 18  then
										begin
											p = ((te))-1;
											begin
												emit(:UNION, ts, te, meta) 
											end
											
										end
										when 19  then
										begin
											p = ((te))-1;
											begin
												emit(:ENUM, ts, te, meta) 
											end
											
										end
										when 20  then
										begin
											p = ((te))-1;
											begin
												emit(:INPUT, ts, te, meta) 
											end
											
										end
										when 21  then
										begin
											p = ((te))-1;
											begin
												emit(:DIRECTIVE, ts, te, meta) 
											end
											
										end
										when 29  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts, te, meta, block: false) 
											end
											
										end
										when 30  then
										begin
											p = ((te))-1;
											begin
												emit_string(ts, te, meta, block: true) 
											end
											
										end
										when 38  then
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
									act = 2;
									
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
									act = 3;
									
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
									act = 4;
									
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
									act = 5;
									
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
						when 48  then
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
						when 50  then
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
						when 51  then
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
						when 55  then
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
						when 44  then
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
						when 46  then
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
						when 56  then
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
						when 40  then
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
						when 45  then
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
						when 39  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 21;
									
								end
								
							end
							
						end
						when 31  then
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
						when 4  then
						begin
							begin
								begin
									te = p+1;
									
								end
								
							end
							begin
								begin
									act = 30;
									
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
									act = 38;
									
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
				if ( cs == 0  )
					_cont = 0;
					
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
:COMMENT,
meta[:data][ts, te - ts].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING),
meta[:line],
meta[:col],
meta[:previous_token],
)

meta[:previous_token] = token

meta[:col] += te - ts
end

def self.emit(token_name, ts, te, meta, token_value = nil)
token_value ||= meta[:data][ts, te - ts].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING)
meta[:tokens] << token = GraphQL::Language::Token.new(
token_name,
token_value,
meta[:line],
meta[:col],
meta[:previous_token],
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
value = meta[:data][ts + quotes_length, te - ts - 2 * quotes_length].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING) || ''
line_incr = 0
if block && !value.empty?
line_incr = value.count("\n")
value = GraphQL::Language::BlockString.trim_whitespace(value)
end
# TODO: replace with `String#match?` when we support only Ruby 2.4+
# (It's faster: https://bugs.ruby-lang.org/issues/8110)
if !value.valid_encoding? || !value.match?(VALID_STRING)
meta[:tokens] << token = GraphQL::Language::Token.new(
:BAD_UNICODE_ESCAPE,
value,
meta[:line],
meta[:col],
meta[:previous_token],
)
else
replace_escaped_characters_in_place(value)

if !value.valid_encoding?
	meta[:tokens] << token = GraphQL::Language::Token.new(
	:BAD_UNICODE_ESCAPE,
	value,
	meta[:line],
	meta[:col],
	meta[:previous_token],
	)
	else
	meta[:tokens] << token = GraphQL::Language::Token.new(
	:STRING,
	value,
	meta[:line],
	meta[:col],
	meta[:previous_token],
	)
	end
end

meta[:previous_token] = token
meta[:col] += te - ts
meta[:line] += line_incr
end
end
end
end
