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
4, 21, 4, 21, 4, 21, 4, 4, 4, 4, 4, 21, 4, 4, 4, 4, 13, 14, 13, 14, 10, 14, 12, 12, 0, 47, 0, 0, 4, 21, 4, 21, 4, 4, 4, 4, 4, 4, 4, 21, 4, 4, 4, 4, 1, 1, 13, 14, 10, 27, 13, 14, 10, 27, 10, 27, 12, 12, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 13, 44, 0 , 
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
0, 18, 36, 54, 55, 56, 74, 75, 76, 78, 80, 85, 86, 134, 135, 153, 171, 172, 173, 174, 192, 193, 194, 195, 197, 215, 217, 235, 253, 254, 286, 318, 350, 382, 414, 446, 478, 510, 542, 574, 606, 638, 670, 702, 734, 766, 798, 830, 862, 894, 926, 958, 990, 1022, 1054, 1086, 1118, 1150, 1182, 1214, 1246, 1278, 1310, 1342, 1374, 1406, 1438, 1470, 1502, 1534, 1566, 1598, 1630, 1662, 1694, 1726, 1758, 1790, 1822, 1854, 1886, 1918, 1950, 1982, 2014, 2046, 2078, 2110, 2142, 2174, 2206, 2238, 2270, 2302, 2334, 2366, 2398, 2430, 2462, 2494, 2526, 2558, 2590, 2622, 2654, 2686, 2718, 2750, 2782, 2814, 2846, 2878, 2910, 2942, 2974, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_indicies 
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 4, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 6, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 8, 9, 10, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 11, 12, 13, 13, 15, 15, 16, 16, 0, 13, 13, 18, 20, 21, 19, 22, 23, 24, 25, 26, 27, 28, 19, 29, 30, 31, 32, 33, 34, 35, 36, 36, 37, 19, 38, 36, 36, 36, 39, 40, 41, 36, 36, 42, 36, 43, 44, 45, 36, 46, 36, 47, 48, 49, 36, 36, 36, 50, 51, 52, 20, 55, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 5, 58, 59, 60, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 7, 61, 9, 62, 31, 32, 16, 16, 64, 13, 13, 63, 63, 63, 63, 65, 63, 63, 63, 63, 63, 63, 63, 65, 13, 13, 16, 16, 66, 15, 15, 66, 66, 66, 66, 65, 66, 66, 66, 66, 66, 66, 66, 65, 16, 16, 64, 32, 32, 63, 63, 63, 63, 65, 63, 63, 63, 63, 63, 63, 63, 65, 67, 36, 36, 0, 0, 0, 36, 36, 0, 0, 0, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 69, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 70, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 71, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 72, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 73, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 74, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 75, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 76, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 77, 36, 36, 36, 36, 36, 36, 36, 36, 78, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 79, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 80, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 81, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 82, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 83, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 84, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 85, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 86, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 87, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 88, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 89, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 90, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 91, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 92, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 93, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 94, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 95, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 96, 97, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 98, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 99, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 100, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 101, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 102, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 103, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 104, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 105, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 106, 36, 36, 36, 107, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 108, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 109, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 110, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 111, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 112, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 113, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 114, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 115, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 116, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 117, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 118, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 119, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 120, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 121, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 122, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 123, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 124, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 125, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 126, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 127, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 128, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 129, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 130, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 131, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 132, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 133, 36, 36, 36, 36, 36, 36, 134, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 135, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 136, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 137, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 138, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 139, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 140, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 141, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 142, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 143, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 144, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 145, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 146, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 147, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 148, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 149, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 150, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 151, 36, 36, 36, 36, 36, 152, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 153, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 154, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 155, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 156, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 157, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 158, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 159, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 68, 68, 68, 36, 36, 68, 68, 68, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 160, 36, 36, 36, 36, 36, 36, 36, 36, 36, 36, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_defaults 
	private :_graphql_lexer_index_defaults, :_graphql_lexer_index_defaults=
end
self._graphql_lexer_index_defaults = [
1, 1, 5, 5, 5, 5, 5, 5, 0, 14, 0, 17, 19, 53, 1, 1, 56, 57, 57, 5, 5, 5, 24, 54, 63, 66, 66, 63, 54, 0, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 68, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_cond_spaces 
	private :_graphql_lexer_trans_cond_spaces, :_graphql_lexer_trans_cond_spaces=
end
self._graphql_lexer_trans_cond_spaces = [
-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
12, 0, 12, 1, 15, 2, 3, 5, 4, 17, 6, 7, 19, 25, 12, 26, 8, 12, 12, 12, 13, 12, 12, 14, 22, 12, 12, 12, 12, 23, 28, 24, 27, 12, 12, 12, 29, 12, 12, 30, 38, 45, 55, 73, 80, 83, 84, 88, 106, 111, 12, 12, 12, 12, 12, 16, 12, 12, 18, 12, 20, 21, 12, 12, 9, 10, 12, 11, 12, 31, 32, 33, 34, 35, 36, 37, 29, 39, 41, 40, 29, 42, 43, 44, 29, 46, 49, 47, 48, 29, 50, 51, 52, 53, 54, 29, 56, 64, 57, 58, 59, 60, 61, 62, 63, 29, 65, 67, 66, 29, 68, 69, 70, 71, 72, 29, 74, 75, 76, 77, 78, 79, 29, 81, 82, 29, 29, 85, 86, 87, 29, 89, 96, 90, 93, 91, 92, 29, 94, 95, 29, 97, 98, 99, 100, 101, 102, 103, 104, 105, 29, 107, 109, 108, 29, 110, 29, 112, 113, 114, 29, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
1, 0, 2, 0, 3, 0, 0, 0, 0, 0, 0, 0, 4, 0, 5, 6, 0, 7, 8, 11, 0, 12, 13, 14, 0, 15, 16, 17, 18, 0, 19, 20, 20, 21, 22, 23, 24, 25, 26, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 27, 28, 29, 30, 31, 3, 32, 33, 0, 34, 4, 4, 35, 36, 0, 0, 37, 0, 38, 0, 0, 0, 0, 0, 0, 0, 39, 0, 0, 0, 40, 0, 0, 0, 41, 0, 0, 0, 0, 42, 0, 0, 0, 0, 0, 43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 44, 0, 0, 0, 45, 0, 0, 0, 0, 0, 46, 0, 0, 0, 0, 0, 0, 47, 0, 0, 48, 49, 0, 0, 0, 50, 0, 0, 0, 0, 0, 0, 51, 0, 0, 52, 0, 0, 0, 0, 0, 0, 0, 0, 0, 53, 0, 0, 0, 54, 0, 55, 0, 0, 0, 56, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
1, 1, 1, 1, 1, 1, 1, 1, 1, 15, 1, 18, 0, 54, 55, 57, 57, 58, 58, 58, 58, 58, 63, 55, 64, 67, 67, 64, 55, 1, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 69, 0 , 
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
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 , 
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
content_range = (ts + quotes_length)...(te - quotes_length)
value = meta[:data][content_range].pack(PACK_DIRECTIVE).force_encoding(UTF_8_ENCODING) || ''
line_incr = 0
if block && !value.length.zero?
line_incr = value.count("\n")
value = GraphQL::Language::BlockString.trim_whitespace(value)
end
# TODO: replace with `String#match?` when we support only Ruby 2.4+
# (It's faster: https://bugs.ruby-lang.org/issues/8110)
if !value.valid_encoding? || value !~ VALID_STRING
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
meta[:line] += line_incr
end
end
end
end
