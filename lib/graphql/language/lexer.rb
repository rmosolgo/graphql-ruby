
# line 1 "lib/graphql/language/lexer.rl"

# line 98 "lib/graphql/language/lexer.rl"



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

      
# line 27 "lib/graphql/language/lexer.rb"
class << self
	attr_accessor :_graphql_lexer_actions
	private :_graphql_lexer_actions, :_graphql_lexer_actions=
end
self._graphql_lexer_actions = [
	0, 1, 0, 1, 1, 1, 2, 1, 
	25, 1, 26, 1, 27, 1, 28, 1, 
	29, 1, 30, 1, 31, 1, 32, 1, 
	33, 1, 34, 1, 35, 1, 36, 1, 
	37, 1, 38, 1, 39, 1, 40, 1, 
	41, 1, 42, 1, 43, 1, 44, 1, 
	45, 1, 46, 1, 47, 1, 48, 1, 
	49, 2, 2, 3, 2, 2, 4, 2, 
	2, 5, 2, 2, 6, 2, 2, 7, 
	2, 2, 8, 2, 2, 9, 2, 2, 
	10, 2, 2, 11, 2, 2, 12, 2, 
	2, 13, 2, 2, 14, 2, 2, 15, 
	2, 2, 16, 2, 2, 17, 2, 2, 
	18, 2, 2, 19, 2, 2, 20, 2, 
	2, 21, 2, 2, 22, 2, 2, 23, 
	2, 2, 24
]

class << self
	attr_accessor :_graphql_lexer_key_offsets
	private :_graphql_lexer_key_offsets, :_graphql_lexer_key_offsets=
end
self._graphql_lexer_key_offsets = [
	0, 2, 4, 6, 8, 12, 13, 53, 
	56, 58, 60, 63, 70, 72, 78, 85, 
	86, 93, 101, 109, 117, 125, 133, 141, 
	149, 157, 165, 173, 181, 190, 198, 206, 
	214, 222, 230, 238, 246, 254, 262, 271, 
	279, 287, 295, 303, 311, 319, 327, 335, 
	344, 352, 360, 368, 376, 384, 392, 400, 
	408, 416, 424, 432, 440, 448, 456, 464, 
	472, 480, 488, 496, 504, 512, 520, 528, 
	537, 546, 554, 562, 570, 578, 586, 594, 
	602, 610, 618, 626, 634, 642, 650, 658, 
	666, 674, 683, 691, 699, 707, 715, 723, 
	731, 739
]

class << self
	attr_accessor :_graphql_lexer_trans_keys
	private :_graphql_lexer_trans_keys, :_graphql_lexer_trans_keys=
end
self._graphql_lexer_trans_keys = [
	34, 92, 34, 92, 48, 57, 48, 57, 
	43, 45, 48, 57, 46, 9, 10, 13, 
	32, 33, 34, 35, 36, 40, 41, 44, 
	45, 46, 48, 58, 61, 64, 91, 93, 
	95, 100, 101, 102, 105, 109, 110, 111, 
	113, 115, 116, 117, 123, 124, 125, 49, 
	57, 65, 90, 97, 122, 9, 32, 44, 
	34, 92, 10, 13, 48, 49, 57, 43, 
	45, 46, 69, 101, 48, 57, 48, 57, 
	43, 45, 69, 101, 48, 57, 43, 45, 
	46, 69, 101, 48, 57, 46, 95, 48, 
	57, 65, 90, 97, 122, 95, 105, 48, 
	57, 65, 90, 97, 122, 95, 114, 48, 
	57, 65, 90, 97, 122, 95, 101, 48, 
	57, 65, 90, 97, 122, 95, 99, 48, 
	57, 65, 90, 97, 122, 95, 116, 48, 
	57, 65, 90, 97, 122, 95, 105, 48, 
	57, 65, 90, 97, 122, 95, 118, 48, 
	57, 65, 90, 97, 122, 95, 101, 48, 
	57, 65, 90, 97, 122, 95, 110, 48, 
	57, 65, 90, 97, 122, 95, 117, 48, 
	57, 65, 90, 97, 122, 95, 109, 48, 
	57, 65, 90, 97, 122, 95, 97, 114, 
	48, 57, 65, 90, 98, 122, 95, 108, 
	48, 57, 65, 90, 97, 122, 95, 115, 
	48, 57, 65, 90, 97, 122, 95, 101, 
	48, 57, 65, 90, 97, 122, 95, 97, 
	48, 57, 65, 90, 98, 122, 95, 103, 
	48, 57, 65, 90, 97, 122, 95, 109, 
	48, 57, 65, 90, 97, 122, 95, 101, 
	48, 57, 65, 90, 97, 122, 95, 110, 
	48, 57, 65, 90, 97, 122, 95, 116, 
	48, 57, 65, 90, 97, 122, 95, 109, 
	110, 48, 57, 65, 90, 97, 122, 95, 
	112, 48, 57, 65, 90, 97, 122, 95, 
	108, 48, 57, 65, 90, 97, 122, 95, 
	101, 48, 57, 65, 90, 97, 122, 95, 
	109, 48, 57, 65, 90, 97, 122, 95, 
	101, 48, 57, 65, 90, 97, 122, 95, 
	110, 48, 57, 65, 90, 97, 122, 95, 
	116, 48, 57, 65, 90, 97, 122, 95, 
	115, 48, 57, 65, 90, 97, 122, 95, 
	112, 116, 48, 57, 65, 90, 97, 122, 
	95, 117, 48, 57, 65, 90, 97, 122, 
	95, 116, 48, 57, 65, 90, 97, 122, 
	95, 101, 48, 57, 65, 90, 97, 122, 
	95, 114, 48, 57, 65, 90, 97, 122, 
	95, 102, 48, 57, 65, 90, 97, 122, 
	95, 97, 48, 57, 65, 90, 98, 122, 
	95, 99, 48, 57, 65, 90, 97, 122, 
	95, 101, 48, 57, 65, 90, 97, 122, 
	95, 117, 48, 57, 65, 90, 97, 122, 
	95, 116, 48, 57, 65, 90, 97, 122, 
	95, 97, 48, 57, 65, 90, 98, 122, 
	95, 116, 48, 57, 65, 90, 97, 122, 
	95, 105, 48, 57, 65, 90, 97, 122, 
	95, 111, 48, 57, 65, 90, 97, 122, 
	95, 110, 48, 57, 65, 90, 97, 122, 
	95, 117, 48, 57, 65, 90, 97, 122, 
	95, 108, 48, 57, 65, 90, 97, 122, 
	95, 108, 48, 57, 65, 90, 97, 122, 
	95, 110, 48, 57, 65, 90, 97, 122, 
	95, 117, 48, 57, 65, 90, 97, 122, 
	95, 101, 48, 57, 65, 90, 97, 122, 
	95, 114, 48, 57, 65, 90, 97, 122, 
	95, 121, 48, 57, 65, 90, 97, 122, 
	95, 99, 117, 48, 57, 65, 90, 97, 
	122, 95, 97, 104, 48, 57, 65, 90, 
	98, 122, 95, 108, 48, 57, 65, 90, 
	97, 122, 95, 97, 48, 57, 65, 90, 
	98, 122, 95, 114, 48, 57, 65, 90, 
	97, 122, 95, 101, 48, 57, 65, 90, 
	97, 122, 95, 109, 48, 57, 65, 90, 
	97, 122, 95, 97, 48, 57, 65, 90, 
	98, 122, 95, 98, 48, 57, 65, 90, 
	97, 122, 95, 115, 48, 57, 65, 90, 
	97, 122, 95, 99, 48, 57, 65, 90, 
	97, 122, 95, 114, 48, 57, 65, 90, 
	97, 122, 95, 105, 48, 57, 65, 90, 
	97, 122, 95, 112, 48, 57, 65, 90, 
	97, 122, 95, 116, 48, 57, 65, 90, 
	97, 122, 95, 105, 48, 57, 65, 90, 
	97, 122, 95, 111, 48, 57, 65, 90, 
	97, 122, 95, 110, 48, 57, 65, 90, 
	97, 122, 95, 114, 121, 48, 57, 65, 
	90, 97, 122, 95, 117, 48, 57, 65, 
	90, 97, 122, 95, 101, 48, 57, 65, 
	90, 97, 122, 95, 112, 48, 57, 65, 
	90, 97, 122, 95, 101, 48, 57, 65, 
	90, 97, 122, 95, 110, 48, 57, 65, 
	90, 97, 122, 95, 105, 48, 57, 65, 
	90, 97, 122, 95, 111, 48, 57, 65, 
	90, 97, 122, 95, 110, 48, 57, 65, 
	90, 97, 122, 0
]

class << self
	attr_accessor :_graphql_lexer_single_lengths
	private :_graphql_lexer_single_lengths, :_graphql_lexer_single_lengths=
end
self._graphql_lexer_single_lengths = [
	2, 2, 0, 0, 2, 1, 34, 3, 
	2, 2, 1, 5, 0, 4, 5, 1, 
	1, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 3, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 3, 2, 
	2, 2, 2, 2, 2, 2, 2, 3, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 3, 
	3, 2, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2, 
	2, 3, 2, 2, 2, 2, 2, 2, 
	2, 2
]

class << self
	attr_accessor :_graphql_lexer_range_lengths
	private :_graphql_lexer_range_lengths, :_graphql_lexer_range_lengths=
end
self._graphql_lexer_range_lengths = [
	0, 0, 1, 1, 1, 0, 3, 0, 
	0, 0, 1, 1, 1, 1, 1, 0, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3
]

class << self
	attr_accessor :_graphql_lexer_index_offsets
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
	0, 3, 6, 8, 10, 14, 16, 54, 
	58, 61, 64, 67, 74, 76, 82, 89, 
	91, 96, 102, 108, 114, 120, 126, 132, 
	138, 144, 150, 156, 162, 169, 175, 181, 
	187, 193, 199, 205, 211, 217, 223, 230, 
	236, 242, 248, 254, 260, 266, 272, 278, 
	285, 291, 297, 303, 309, 315, 321, 327, 
	333, 339, 345, 351, 357, 363, 369, 375, 
	381, 387, 393, 399, 405, 411, 417, 423, 
	430, 437, 443, 449, 455, 461, 467, 473, 
	479, 485, 491, 497, 503, 509, 515, 521, 
	527, 533, 540, 546, 552, 558, 564, 570, 
	576, 582
]

class << self
	attr_accessor :_graphql_lexer_trans_targs
	private :_graphql_lexer_trans_targs, :_graphql_lexer_trans_targs=
end
self._graphql_lexer_trans_targs = [
	6, 1, 0, 8, 1, 0, 12, 6, 
	13, 6, 2, 2, 12, 6, 6, 6, 
	7, 6, 6, 7, 6, 8, 9, 6, 
	6, 6, 7, 10, 15, 11, 6, 6, 
	6, 6, 6, 16, 17, 25, 28, 38, 
	56, 63, 66, 67, 71, 89, 94, 6, 
	6, 6, 14, 16, 16, 6, 7, 7, 
	7, 6, 6, 1, 0, 6, 6, 9, 
	11, 14, 6, 2, 2, 3, 4, 4, 
	12, 6, 12, 6, 2, 2, 4, 4, 
	13, 6, 2, 2, 3, 4, 4, 14, 
	6, 5, 6, 16, 16, 16, 16, 6, 
	16, 18, 16, 16, 16, 6, 16, 19, 
	16, 16, 16, 6, 16, 20, 16, 16, 
	16, 6, 16, 21, 16, 16, 16, 6, 
	16, 22, 16, 16, 16, 6, 16, 23, 
	16, 16, 16, 6, 16, 24, 16, 16, 
	16, 6, 16, 16, 16, 16, 16, 6, 
	16, 26, 16, 16, 16, 6, 16, 27, 
	16, 16, 16, 6, 16, 16, 16, 16, 
	16, 6, 16, 29, 32, 16, 16, 16, 
	6, 16, 30, 16, 16, 16, 6, 16, 
	31, 16, 16, 16, 6, 16, 16, 16, 
	16, 16, 6, 16, 33, 16, 16, 16, 
	6, 16, 34, 16, 16, 16, 6, 16, 
	35, 16, 16, 16, 6, 16, 36, 16, 
	16, 16, 6, 16, 37, 16, 16, 16, 
	6, 16, 16, 16, 16, 16, 6, 16, 
	39, 47, 16, 16, 16, 6, 16, 40, 
	16, 16, 16, 6, 16, 41, 16, 16, 
	16, 6, 16, 42, 16, 16, 16, 6, 
	16, 43, 16, 16, 16, 6, 16, 44, 
	16, 16, 16, 6, 16, 45, 16, 16, 
	16, 6, 16, 46, 16, 16, 16, 6, 
	16, 16, 16, 16, 16, 6, 16, 48, 
	50, 16, 16, 16, 6, 16, 49, 16, 
	16, 16, 6, 16, 16, 16, 16, 16, 
	6, 16, 51, 16, 16, 16, 6, 16, 
	52, 16, 16, 16, 6, 16, 53, 16, 
	16, 16, 6, 16, 54, 16, 16, 16, 
	6, 16, 55, 16, 16, 16, 6, 16, 
	16, 16, 16, 16, 6, 16, 57, 16, 
	16, 16, 6, 16, 58, 16, 16, 16, 
	6, 16, 59, 16, 16, 16, 6, 16, 
	60, 16, 16, 16, 6, 16, 61, 16, 
	16, 16, 6, 16, 62, 16, 16, 16, 
	6, 16, 16, 16, 16, 16, 6, 16, 
	64, 16, 16, 16, 6, 16, 65, 16, 
	16, 16, 6, 16, 16, 16, 16, 16, 
	6, 16, 16, 16, 16, 16, 6, 16, 
	68, 16, 16, 16, 6, 16, 69, 16, 
	16, 16, 6, 16, 70, 16, 16, 16, 
	6, 16, 16, 16, 16, 16, 6, 16, 
	72, 79, 16, 16, 16, 6, 16, 73, 
	76, 16, 16, 16, 6, 16, 74, 16, 
	16, 16, 6, 16, 75, 16, 16, 16, 
	6, 16, 16, 16, 16, 16, 6, 16, 
	77, 16, 16, 16, 6, 16, 78, 16, 
	16, 16, 6, 16, 16, 16, 16, 16, 
	6, 16, 80, 16, 16, 16, 6, 16, 
	81, 16, 16, 16, 6, 16, 82, 16, 
	16, 16, 6, 16, 83, 16, 16, 16, 
	6, 16, 84, 16, 16, 16, 6, 16, 
	85, 16, 16, 16, 6, 16, 86, 16, 
	16, 16, 6, 16, 87, 16, 16, 16, 
	6, 16, 88, 16, 16, 16, 6, 16, 
	16, 16, 16, 16, 6, 16, 90, 92, 
	16, 16, 16, 6, 16, 91, 16, 16, 
	16, 6, 16, 16, 16, 16, 16, 6, 
	16, 93, 16, 16, 16, 6, 16, 16, 
	16, 16, 16, 6, 16, 95, 16, 16, 
	16, 6, 16, 96, 16, 16, 16, 6, 
	16, 97, 16, 16, 16, 6, 16, 16, 
	16, 16, 16, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 6, 6, 6, 
	6, 6, 6, 6, 6, 0
]

class << self
	attr_accessor :_graphql_lexer_trans_actions
	private :_graphql_lexer_trans_actions, :_graphql_lexer_trans_actions=
end
self._graphql_lexer_trans_actions = [
	21, 0, 0, 114, 0, 0, 0, 55, 
	60, 51, 0, 0, 0, 55, 27, 53, 
	0, 35, 35, 0, 31, 120, 0, 23, 
	13, 11, 0, 0, 5, 57, 19, 29, 
	25, 17, 15, 117, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 9, 
	33, 7, 57, 117, 117, 37, 0, 0, 
	0, 45, 21, 0, 0, 47, 47, 0, 
	57, 57, 49, 0, 0, 0, 0, 0, 
	0, 39, 0, 41, 0, 0, 0, 0, 
	60, 41, 0, 0, 0, 0, 0, 57, 
	39, 0, 49, 117, 117, 117, 117, 55, 
	117, 0, 117, 117, 117, 43, 117, 0, 
	117, 117, 117, 43, 117, 0, 117, 117, 
	117, 43, 117, 0, 117, 117, 117, 43, 
	117, 0, 117, 117, 117, 43, 117, 0, 
	117, 117, 117, 43, 117, 0, 117, 117, 
	117, 43, 117, 111, 117, 117, 117, 43, 
	117, 0, 117, 117, 117, 43, 117, 0, 
	117, 117, 117, 43, 117, 105, 117, 117, 
	117, 43, 117, 0, 0, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 72, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 66, 117, 117, 117, 43, 117, 
	0, 0, 117, 117, 117, 43, 117, 0, 
	117, 117, 117, 43, 117, 0, 117, 117, 
	117, 43, 117, 0, 117, 117, 117, 43, 
	117, 0, 117, 117, 117, 43, 117, 0, 
	117, 117, 117, 43, 117, 0, 117, 117, 
	117, 43, 117, 0, 117, 117, 117, 43, 
	117, 96, 117, 117, 117, 43, 117, 0, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 108, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	99, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 81, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 75, 117, 117, 117, 
	43, 117, 63, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 78, 117, 117, 117, 43, 117, 
	0, 0, 117, 117, 117, 43, 117, 0, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 90, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 87, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	0, 117, 117, 117, 43, 117, 0, 117, 
	117, 117, 43, 117, 0, 117, 117, 117, 
	43, 117, 0, 117, 117, 117, 43, 117, 
	84, 117, 117, 117, 43, 117, 0, 0, 
	117, 117, 117, 43, 117, 0, 117, 117, 
	117, 43, 117, 69, 117, 117, 117, 43, 
	117, 0, 117, 117, 117, 43, 117, 93, 
	117, 117, 117, 43, 117, 0, 117, 117, 
	117, 43, 117, 0, 117, 117, 117, 43, 
	117, 0, 117, 117, 117, 43, 117, 102, 
	117, 117, 117, 43, 55, 55, 55, 51, 
	55, 53, 45, 55, 47, 49, 39, 41, 
	41, 39, 49, 55, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 0
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
	0, 0, 0, 0, 0, 0, 1, 0, 
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
	0, 0
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
	0, 0, 0, 0, 0, 0, 3, 0, 
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
	0, 0
]

class << self
	attr_accessor :_graphql_lexer_eof_trans
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
	604, 604, 604, 592, 604, 594, 0, 595, 
	604, 597, 603, 602, 601, 601, 602, 603, 
	604, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685, 685, 685, 685, 685, 685, 685, 
	685, 685
]

class << self
	attr_accessor :graphql_lexer_start
end
self.graphql_lexer_start = 6;
class << self
	attr_accessor :graphql_lexer_first_final
end
self.graphql_lexer_first_final = 6;
class << self
	attr_accessor :graphql_lexer_error
end
self.graphql_lexer_error = -1;

class << self
	attr_accessor :graphql_lexer_en_main
end
self.graphql_lexer_en_main = 6;


# line 119 "lib/graphql/language/lexer.rl"

      def self.run_lexer(query_string)
        data = query_string.unpack("c*")
        eof = data.length

        meta = {
          line: 1,
          col: 1,
          data: data,
          tokens: []
        }

        
# line 511 "lib/graphql/language/lexer.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = graphql_lexer_start
	ts = nil
	te = nil
	act = 0
end

# line 132 "lib/graphql/language/lexer.rl"

        emit_token = ->(name) {
          emit(name, ts, te, meta)
        }

        
# line 528 "lib/graphql/language/lexer.rb"
begin
	_klen, _trans, _keys, _acts, _nacts = nil
	_goto_level = 0
	_resume = 10
	_eof_trans = 15
	_again = 20
	_test_eof = 30
	_out = 40
	while true
	_trigger_goto = false
	if _goto_level <= 0
	if p == pe
		_goto_level = _test_eof
		next
	end
	end
	if _goto_level <= _resume
	_acts = _graphql_lexer_from_state_actions[cs]
	_nacts = _graphql_lexer_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _graphql_lexer_actions[_acts - 1]
			when 1 then
# line 1 "NONE"
		begin
ts = p
		end
# line 558 "lib/graphql/language/lexer.rb"
		end # from state action switch
	end
	if _trigger_goto
		next
	end
	_keys = _graphql_lexer_key_offsets[cs]
	_trans = _graphql_lexer_index_offsets[cs]
	_klen = _graphql_lexer_single_lengths[cs]
	_break_match = false
	
	begin
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + _klen - 1

	     loop do
	        break if _upper < _lower
	        _mid = _lower + ( (_upper - _lower) >> 1 )

	        if data[p].ord < _graphql_lexer_trans_keys[_mid]
	           _upper = _mid - 1
	        elsif data[p].ord > _graphql_lexer_trans_keys[_mid]
	           _lower = _mid + 1
	        else
	           _trans += (_mid - _keys)
	           _break_match = true
	           break
	        end
	     end # loop
	     break if _break_match
	     _keys += _klen
	     _trans += _klen
	  end
	  _klen = _graphql_lexer_range_lengths[cs]
	  if _klen > 0
	     _lower = _keys
	     _upper = _keys + (_klen << 1) - 2
	     loop do
	        break if _upper < _lower
	        _mid = _lower + (((_upper-_lower) >> 1) & ~1)
	        if data[p].ord < _graphql_lexer_trans_keys[_mid]
	          _upper = _mid - 2
	        elsif data[p].ord > _graphql_lexer_trans_keys[_mid+1]
	          _lower = _mid + 2
	        else
	          _trans += ((_mid - _keys) >> 1)
	          _break_match = true
	          break
	        end
	     end # loop
	     break if _break_match
	     _trans += _klen
	  end
	end while false
	end
	if _goto_level <= _eof_trans
	cs = _graphql_lexer_trans_targs[_trans]
	if _graphql_lexer_trans_actions[_trans] != 0
		_acts = _graphql_lexer_trans_actions[_trans]
		_nacts = _graphql_lexer_actions[_acts]
		_acts += 1
		while _nacts > 0
			_nacts -= 1
			_acts += 1
			case _graphql_lexer_actions[_acts - 1]
when 2 then
# line 1 "NONE"
		begin
te = p+1
		end
when 3 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
act = 1;		end
when 4 then
# line 53 "lib/graphql/language/lexer.rl"
		begin
act = 2;		end
when 5 then
# line 54 "lib/graphql/language/lexer.rl"
		begin
act = 3;		end
when 6 then
# line 55 "lib/graphql/language/lexer.rl"
		begin
act = 4;		end
when 7 then
# line 56 "lib/graphql/language/lexer.rl"
		begin
act = 5;		end
when 8 then
# line 57 "lib/graphql/language/lexer.rl"
		begin
act = 6;		end
when 9 then
# line 58 "lib/graphql/language/lexer.rl"
		begin
act = 7;		end
when 10 then
# line 59 "lib/graphql/language/lexer.rl"
		begin
act = 8;		end
when 11 then
# line 60 "lib/graphql/language/lexer.rl"
		begin
act = 9;		end
when 12 then
# line 61 "lib/graphql/language/lexer.rl"
		begin
act = 10;		end
when 13 then
# line 62 "lib/graphql/language/lexer.rl"
		begin
act = 11;		end
when 14 then
# line 63 "lib/graphql/language/lexer.rl"
		begin
act = 12;		end
when 15 then
# line 64 "lib/graphql/language/lexer.rl"
		begin
act = 13;		end
when 16 then
# line 65 "lib/graphql/language/lexer.rl"
		begin
act = 14;		end
when 17 then
# line 66 "lib/graphql/language/lexer.rl"
		begin
act = 15;		end
when 18 then
# line 67 "lib/graphql/language/lexer.rl"
		begin
act = 16;		end
when 19 then
# line 68 "lib/graphql/language/lexer.rl"
		begin
act = 17;		end
when 20 then
# line 69 "lib/graphql/language/lexer.rl"
		begin
act = 18;		end
when 21 then
# line 70 "lib/graphql/language/lexer.rl"
		begin
act = 19;		end
when 22 then
# line 78 "lib/graphql/language/lexer.rl"
		begin
act = 27;		end
when 23 then
# line 85 "lib/graphql/language/lexer.rl"
		begin
act = 34;		end
when 24 then
# line 95 "lib/graphql/language/lexer.rl"
		begin
act = 38;		end
when 25 then
# line 71 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RCURLY)  end
		end
when 26 then
# line 72 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LCURLY)  end
		end
when 27 then
# line 73 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RPAREN)  end
		end
when 28 then
# line 74 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LPAREN)  end
		end
when 29 then
# line 75 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RBRACKET)  end
		end
when 30 then
# line 76 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LBRACKET)  end
		end
when 31 then
# line 77 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:COLON)  end
		end
when 32 then
# line 78 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_string(ts + 1, te - 1, meta)  end
		end
when 33 then
# line 79 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:VAR_SIGN)  end
		end
when 34 then
# line 80 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:DIR_SIGN)  end
		end
when 35 then
# line 81 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:ELLIPSIS)  end
		end
when 36 then
# line 82 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:EQUALS)  end
		end
when 37 then
# line 83 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:BANG)  end
		end
when 38 then
# line 84 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:PIPE)  end
		end
when 39 then
# line 87 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin 
      meta[:line] += 1
      meta[:col] = 1
     end
		end
when 40 then
# line 95 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 41 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:INT)  end
		end
when 42 then
# line 53 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:FLOAT)  end
		end
when 43 then
# line 85 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:IDENTIFIER)  end
		end
when 44 then
# line 92 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 45 then
# line 93 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 46 then
# line 95 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 47 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:INT)  end
		end
when 48 then
# line 95 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 49 then
# line 1 "NONE"
		begin
	case act
	when 1 then
	begin begin p = ((te))-1; end
 emit_token.call(:INT) end
	when 2 then
	begin begin p = ((te))-1; end
 emit_token.call(:FLOAT) end
	when 3 then
	begin begin p = ((te))-1; end
 emit_token.call(:ON) end
	when 4 then
	begin begin p = ((te))-1; end
 emit_token.call(:FRAGMENT) end
	when 5 then
	begin begin p = ((te))-1; end
 emit_token.call(:TRUE) end
	when 6 then
	begin begin p = ((te))-1; end
 emit_token.call(:FALSE) end
	when 7 then
	begin begin p = ((te))-1; end
 emit_token.call(:NULL) end
	when 8 then
	begin begin p = ((te))-1; end
 emit_token.call(:QUERY) end
	when 9 then
	begin begin p = ((te))-1; end
 emit_token.call(:MUTATION) end
	when 10 then
	begin begin p = ((te))-1; end
 emit_token.call(:SUBSCRIPTION) end
	when 11 then
	begin begin p = ((te))-1; end
 emit_token.call(:SCHEMA) end
	when 12 then
	begin begin p = ((te))-1; end
 emit_token.call(:SCALAR) end
	when 13 then
	begin begin p = ((te))-1; end
 emit_token.call(:TYPE) end
	when 14 then
	begin begin p = ((te))-1; end
 emit_token.call(:IMPLEMENTS) end
	when 15 then
	begin begin p = ((te))-1; end
 emit_token.call(:INTERFACE) end
	when 16 then
	begin begin p = ((te))-1; end
 emit_token.call(:UNION) end
	when 17 then
	begin begin p = ((te))-1; end
 emit_token.call(:ENUM) end
	when 18 then
	begin begin p = ((te))-1; end
 emit_token.call(:INPUT) end
	when 19 then
	begin begin p = ((te))-1; end
 emit_token.call(:DIRECTIVE) end
	when 27 then
	begin begin p = ((te))-1; end
 emit_string(ts + 1, te - 1, meta) end
	when 34 then
	begin begin p = ((te))-1; end
 emit_token.call(:IDENTIFIER) end
	when 38 then
	begin begin p = ((te))-1; end
 emit_token.call(:UNKNOWN_CHAR) end
end 
			end
# line 936 "lib/graphql/language/lexer.rb"
			end # action switch
		end
	end
	if _trigger_goto
		next
	end
	end
	if _goto_level <= _again
	_acts = _graphql_lexer_to_state_actions[cs]
	_nacts = _graphql_lexer_actions[_acts]
	_acts += 1
	while _nacts > 0
		_nacts -= 1
		_acts += 1
		case _graphql_lexer_actions[_acts - 1]
when 0 then
# line 1 "NONE"
		begin
ts = nil;		end
# line 956 "lib/graphql/language/lexer.rb"
		end # to state action switch
	end
	if _trigger_goto
		next
	end
	p += 1
	if p != pe
		_goto_level = _resume
		next
	end
	end
	if _goto_level <= _test_eof
	if p == eof
	if _graphql_lexer_eof_trans[cs] > 0
		_trans = _graphql_lexer_eof_trans[cs] - 1;
		_goto_level = _eof_trans
		next;
	end
end
	end
	if _goto_level <= _out
		break
	end
	end
	end

# line 138 "lib/graphql/language/lexer.rl"

        meta[:tokens]
      end

      def self.emit(token_name, ts, te, meta)
        meta[:tokens] << GraphQL::Language::Token.new(
          name: token_name,
          value: meta[:data][ts...te].pack("c*"),
          line: meta[:line],
          col: meta[:col],
        )
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

      def self.emit_string(ts, te, meta)
        value = meta[:data][ts...te].pack("c*").force_encoding("UTF-8")
        if value =~ /\\u|\\./ && value !~ ESCAPES
          meta[:tokens] << GraphQL::Language::Token.new(
            name: :BAD_UNICODE_ESCAPE,
            value: value,
            line: meta[:line],
            col: meta[:col],
          )
        else
          replace_escaped_characters_in_place(value)

          meta[:tokens] << GraphQL::Language::Token.new(
            name: :STRING,
            value: value,
            line: meta[:line],
            col: meta[:col],
          )
        end

        meta[:col] += te - ts
      end
    end
  end
end
