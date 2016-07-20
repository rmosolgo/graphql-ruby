
# line 1 "lib/graphql/language/lexer.rl"

# line 96 "lib/graphql/language/lexer.rl"



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
	24, 1, 25, 1, 26, 1, 27, 1, 
	28, 1, 29, 1, 30, 1, 31, 1, 
	32, 1, 33, 1, 34, 1, 35, 1, 
	36, 1, 37, 1, 38, 1, 39, 1, 
	40, 1, 41, 1, 42, 1, 43, 1, 
	44, 1, 45, 1, 46, 1, 47, 1, 
	48, 2, 2, 3, 2, 2, 4, 2, 
	2, 5, 2, 2, 6, 2, 2, 7, 
	2, 2, 8, 2, 2, 9, 2, 2, 
	10, 2, 2, 11, 2, 2, 12, 2, 
	2, 13, 2, 2, 14, 2, 2, 15, 
	2, 2, 16, 2, 2, 17, 2, 2, 
	18, 2, 2, 19, 2, 2, 20, 2, 
	2, 21, 2, 2, 22, 2, 2, 23
]

class << self
	attr_accessor :_graphql_lexer_key_offsets
	private :_graphql_lexer_key_offsets, :_graphql_lexer_key_offsets=
end
self._graphql_lexer_key_offsets = [
	0, 2, 4, 6, 8, 12, 13, 52, 
	55, 57, 59, 62, 69, 71, 77, 84, 
	85, 92, 100, 108, 116, 125, 133, 141, 
	149, 157, 165, 173, 181, 189, 197, 206, 
	214, 222, 230, 238, 246, 254, 262, 270, 
	279, 287, 295, 303, 311, 319, 327, 335, 
	343, 351, 359, 367, 375, 383, 391, 399, 
	407, 415, 423, 431, 439, 447, 455, 463, 
	472, 481, 489, 497, 505, 513, 521, 529, 
	537, 545, 553, 561, 569, 577, 585, 593, 
	601, 609, 618, 626, 634, 642, 650, 658, 
	666, 674
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
	95, 101, 102, 105, 109, 110, 111, 113, 
	115, 116, 117, 123, 124, 125, 49, 57, 
	65, 90, 97, 122, 9, 32, 44, 34, 
	92, 10, 13, 48, 49, 57, 43, 45, 
	46, 69, 101, 48, 57, 48, 57, 43, 
	45, 69, 101, 48, 57, 43, 45, 46, 
	69, 101, 48, 57, 46, 95, 48, 57, 
	65, 90, 97, 122, 95, 110, 48, 57, 
	65, 90, 97, 122, 95, 117, 48, 57, 
	65, 90, 97, 122, 95, 109, 48, 57, 
	65, 90, 97, 122, 95, 97, 114, 48, 
	57, 65, 90, 98, 122, 95, 108, 48, 
	57, 65, 90, 97, 122, 95, 115, 48, 
	57, 65, 90, 97, 122, 95, 101, 48, 
	57, 65, 90, 97, 122, 95, 97, 48, 
	57, 65, 90, 98, 122, 95, 103, 48, 
	57, 65, 90, 97, 122, 95, 109, 48, 
	57, 65, 90, 97, 122, 95, 101, 48, 
	57, 65, 90, 97, 122, 95, 110, 48, 
	57, 65, 90, 97, 122, 95, 116, 48, 
	57, 65, 90, 97, 122, 95, 109, 110, 
	48, 57, 65, 90, 97, 122, 95, 112, 
	48, 57, 65, 90, 97, 122, 95, 108, 
	48, 57, 65, 90, 97, 122, 95, 101, 
	48, 57, 65, 90, 97, 122, 95, 109, 
	48, 57, 65, 90, 97, 122, 95, 101, 
	48, 57, 65, 90, 97, 122, 95, 110, 
	48, 57, 65, 90, 97, 122, 95, 116, 
	48, 57, 65, 90, 97, 122, 95, 115, 
	48, 57, 65, 90, 97, 122, 95, 112, 
	116, 48, 57, 65, 90, 97, 122, 95, 
	117, 48, 57, 65, 90, 97, 122, 95, 
	116, 48, 57, 65, 90, 97, 122, 95, 
	101, 48, 57, 65, 90, 97, 122, 95, 
	114, 48, 57, 65, 90, 97, 122, 95, 
	102, 48, 57, 65, 90, 97, 122, 95, 
	97, 48, 57, 65, 90, 98, 122, 95, 
	99, 48, 57, 65, 90, 97, 122, 95, 
	101, 48, 57, 65, 90, 97, 122, 95, 
	117, 48, 57, 65, 90, 97, 122, 95, 
	116, 48, 57, 65, 90, 97, 122, 95, 
	97, 48, 57, 65, 90, 98, 122, 95, 
	116, 48, 57, 65, 90, 97, 122, 95, 
	105, 48, 57, 65, 90, 97, 122, 95, 
	111, 48, 57, 65, 90, 97, 122, 95, 
	110, 48, 57, 65, 90, 97, 122, 95, 
	117, 48, 57, 65, 90, 97, 122, 95, 
	108, 48, 57, 65, 90, 97, 122, 95, 
	108, 48, 57, 65, 90, 97, 122, 95, 
	110, 48, 57, 65, 90, 97, 122, 95, 
	117, 48, 57, 65, 90, 97, 122, 95, 
	101, 48, 57, 65, 90, 97, 122, 95, 
	114, 48, 57, 65, 90, 97, 122, 95, 
	121, 48, 57, 65, 90, 97, 122, 95, 
	99, 117, 48, 57, 65, 90, 97, 122, 
	95, 97, 104, 48, 57, 65, 90, 98, 
	122, 95, 108, 48, 57, 65, 90, 97, 
	122, 95, 97, 48, 57, 65, 90, 98, 
	122, 95, 114, 48, 57, 65, 90, 97, 
	122, 95, 101, 48, 57, 65, 90, 97, 
	122, 95, 109, 48, 57, 65, 90, 97, 
	122, 95, 97, 48, 57, 65, 90, 98, 
	122, 95, 98, 48, 57, 65, 90, 97, 
	122, 95, 115, 48, 57, 65, 90, 97, 
	122, 95, 99, 48, 57, 65, 90, 97, 
	122, 95, 114, 48, 57, 65, 90, 97, 
	122, 95, 105, 48, 57, 65, 90, 97, 
	122, 95, 112, 48, 57, 65, 90, 97, 
	122, 95, 116, 48, 57, 65, 90, 97, 
	122, 95, 105, 48, 57, 65, 90, 97, 
	122, 95, 111, 48, 57, 65, 90, 97, 
	122, 95, 110, 48, 57, 65, 90, 97, 
	122, 95, 114, 121, 48, 57, 65, 90, 
	97, 122, 95, 117, 48, 57, 65, 90, 
	97, 122, 95, 101, 48, 57, 65, 90, 
	97, 122, 95, 112, 48, 57, 65, 90, 
	97, 122, 95, 101, 48, 57, 65, 90, 
	97, 122, 95, 110, 48, 57, 65, 90, 
	97, 122, 95, 105, 48, 57, 65, 90, 
	97, 122, 95, 111, 48, 57, 65, 90, 
	97, 122, 95, 110, 48, 57, 65, 90, 
	97, 122, 0
]

class << self
	attr_accessor :_graphql_lexer_single_lengths
	private :_graphql_lexer_single_lengths, :_graphql_lexer_single_lengths=
end
self._graphql_lexer_single_lengths = [
	2, 2, 0, 0, 2, 1, 33, 3, 
	2, 2, 1, 5, 0, 4, 5, 1, 
	1, 2, 2, 2, 3, 2, 2, 2, 
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
	3, 3
]

class << self
	attr_accessor :_graphql_lexer_index_offsets
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
	0, 3, 6, 8, 10, 14, 16, 53, 
	57, 60, 63, 66, 73, 75, 81, 88, 
	90, 95, 101, 107, 113, 120, 126, 132, 
	138, 144, 150, 156, 162, 168, 174, 181, 
	187, 193, 199, 205, 211, 217, 223, 229, 
	236, 242, 248, 254, 260, 266, 272, 278, 
	284, 290, 296, 302, 308, 314, 320, 326, 
	332, 338, 344, 350, 356, 362, 368, 374, 
	381, 388, 394, 400, 406, 412, 418, 424, 
	430, 436, 442, 448, 454, 460, 466, 472, 
	478, 484, 491, 497, 503, 509, 515, 521, 
	527, 533
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
	6, 6, 6, 16, 17, 20, 30, 48, 
	55, 58, 59, 63, 81, 86, 6, 6, 
	6, 14, 16, 16, 6, 7, 7, 7, 
	6, 6, 1, 0, 6, 6, 9, 11, 
	14, 6, 2, 2, 3, 4, 4, 12, 
	6, 12, 6, 2, 2, 4, 4, 13, 
	6, 2, 2, 3, 4, 4, 14, 6, 
	5, 6, 16, 16, 16, 16, 6, 16, 
	18, 16, 16, 16, 6, 16, 19, 16, 
	16, 16, 6, 16, 16, 16, 16, 16, 
	6, 16, 21, 24, 16, 16, 16, 6, 
	16, 22, 16, 16, 16, 6, 16, 23, 
	16, 16, 16, 6, 16, 16, 16, 16, 
	16, 6, 16, 25, 16, 16, 16, 6, 
	16, 26, 16, 16, 16, 6, 16, 27, 
	16, 16, 16, 6, 16, 28, 16, 16, 
	16, 6, 16, 29, 16, 16, 16, 6, 
	16, 16, 16, 16, 16, 6, 16, 31, 
	39, 16, 16, 16, 6, 16, 32, 16, 
	16, 16, 6, 16, 33, 16, 16, 16, 
	6, 16, 34, 16, 16, 16, 6, 16, 
	35, 16, 16, 16, 6, 16, 36, 16, 
	16, 16, 6, 16, 37, 16, 16, 16, 
	6, 16, 38, 16, 16, 16, 6, 16, 
	16, 16, 16, 16, 6, 16, 40, 42, 
	16, 16, 16, 6, 16, 41, 16, 16, 
	16, 6, 16, 16, 16, 16, 16, 6, 
	16, 43, 16, 16, 16, 6, 16, 44, 
	16, 16, 16, 6, 16, 45, 16, 16, 
	16, 6, 16, 46, 16, 16, 16, 6, 
	16, 47, 16, 16, 16, 6, 16, 16, 
	16, 16, 16, 6, 16, 49, 16, 16, 
	16, 6, 16, 50, 16, 16, 16, 6, 
	16, 51, 16, 16, 16, 6, 16, 52, 
	16, 16, 16, 6, 16, 53, 16, 16, 
	16, 6, 16, 54, 16, 16, 16, 6, 
	16, 16, 16, 16, 16, 6, 16, 56, 
	16, 16, 16, 6, 16, 57, 16, 16, 
	16, 6, 16, 16, 16, 16, 16, 6, 
	16, 16, 16, 16, 16, 6, 16, 60, 
	16, 16, 16, 6, 16, 61, 16, 16, 
	16, 6, 16, 62, 16, 16, 16, 6, 
	16, 16, 16, 16, 16, 6, 16, 64, 
	71, 16, 16, 16, 6, 16, 65, 68, 
	16, 16, 16, 6, 16, 66, 16, 16, 
	16, 6, 16, 67, 16, 16, 16, 6, 
	16, 16, 16, 16, 16, 6, 16, 69, 
	16, 16, 16, 6, 16, 70, 16, 16, 
	16, 6, 16, 16, 16, 16, 16, 6, 
	16, 72, 16, 16, 16, 6, 16, 73, 
	16, 16, 16, 6, 16, 74, 16, 16, 
	16, 6, 16, 75, 16, 16, 16, 6, 
	16, 76, 16, 16, 16, 6, 16, 77, 
	16, 16, 16, 6, 16, 78, 16, 16, 
	16, 6, 16, 79, 16, 16, 16, 6, 
	16, 80, 16, 16, 16, 6, 16, 16, 
	16, 16, 16, 6, 16, 82, 84, 16, 
	16, 16, 6, 16, 83, 16, 16, 16, 
	6, 16, 16, 16, 16, 16, 6, 16, 
	85, 16, 16, 16, 6, 16, 16, 16, 
	16, 16, 6, 16, 87, 16, 16, 16, 
	6, 16, 88, 16, 16, 16, 6, 16, 
	89, 16, 16, 16, 6, 16, 16, 16, 
	16, 16, 6, 6, 6, 6, 6, 6, 
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
	6, 6, 6, 6, 0
]

class << self
	attr_accessor :_graphql_lexer_trans_actions
	private :_graphql_lexer_trans_actions, :_graphql_lexer_trans_actions=
end
self._graphql_lexer_trans_actions = [
	21, 0, 0, 111, 0, 0, 0, 55, 
	60, 51, 0, 0, 0, 55, 27, 53, 
	0, 35, 35, 0, 31, 117, 0, 23, 
	11, 13, 0, 0, 5, 57, 19, 29, 
	25, 15, 17, 114, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 7, 33, 
	9, 57, 114, 114, 37, 0, 0, 0, 
	45, 21, 0, 0, 47, 47, 0, 57, 
	57, 49, 0, 0, 0, 0, 0, 0, 
	39, 0, 41, 0, 0, 0, 0, 60, 
	41, 0, 0, 0, 0, 0, 57, 39, 
	0, 49, 114, 114, 114, 114, 55, 114, 
	0, 114, 114, 114, 43, 114, 0, 114, 
	114, 114, 43, 114, 105, 114, 114, 114, 
	43, 114, 0, 0, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 72, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 66, 114, 114, 114, 43, 114, 0, 
	0, 114, 114, 114, 43, 114, 0, 114, 
	114, 114, 43, 114, 0, 114, 114, 114, 
	43, 114, 0, 114, 114, 114, 43, 114, 
	0, 114, 114, 114, 43, 114, 0, 114, 
	114, 114, 43, 114, 0, 114, 114, 114, 
	43, 114, 0, 114, 114, 114, 43, 114, 
	96, 114, 114, 114, 43, 114, 0, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 108, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 99, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 81, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 75, 114, 114, 114, 43, 
	114, 63, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 78, 114, 114, 114, 43, 114, 0, 
	0, 114, 114, 114, 43, 114, 0, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 90, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 87, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 0, 
	114, 114, 114, 43, 114, 0, 114, 114, 
	114, 43, 114, 0, 114, 114, 114, 43, 
	114, 0, 114, 114, 114, 43, 114, 84, 
	114, 114, 114, 43, 114, 0, 0, 114, 
	114, 114, 43, 114, 0, 114, 114, 114, 
	43, 114, 69, 114, 114, 114, 43, 114, 
	0, 114, 114, 114, 43, 114, 93, 114, 
	114, 114, 43, 114, 0, 114, 114, 114, 
	43, 114, 0, 114, 114, 114, 43, 114, 
	0, 114, 114, 114, 43, 114, 102, 114, 
	114, 114, 43, 55, 55, 55, 51, 55, 
	53, 45, 55, 47, 49, 39, 41, 41, 
	39, 49, 55, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 43, 43, 43, 43, 
	43, 43, 43, 43, 0
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
	0, 0
]

class << self
	attr_accessor :_graphql_lexer_eof_trans
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
	555, 555, 555, 543, 555, 545, 0, 546, 
	555, 548, 554, 553, 552, 552, 553, 554, 
	555, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628, 628, 628, 628, 628, 628, 628, 
	628, 628
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


# line 117 "lib/graphql/language/lexer.rl"

      def self.run_lexer(query_string)
        data = query_string.unpack("c*")
        eof = data.length

        meta = {
          line: 1,
          col: 1,
          data: data,
          tokens: []
        }

        
# line 481 "lib/graphql/language/lexer.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = graphql_lexer_start
	ts = nil
	te = nil
	act = 0
end

# line 130 "lib/graphql/language/lexer.rl"

        emit_token = -> (name) {
          emit(name, ts, te, meta)
        }

        
# line 498 "lib/graphql/language/lexer.rb"
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
# line 528 "lib/graphql/language/lexer.rb"
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
# line 51 "lib/graphql/language/lexer.rl"
		begin
act = 1;		end
when 4 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
act = 2;		end
when 5 then
# line 53 "lib/graphql/language/lexer.rl"
		begin
act = 3;		end
when 6 then
# line 54 "lib/graphql/language/lexer.rl"
		begin
act = 4;		end
when 7 then
# line 55 "lib/graphql/language/lexer.rl"
		begin
act = 5;		end
when 8 then
# line 56 "lib/graphql/language/lexer.rl"
		begin
act = 6;		end
when 9 then
# line 57 "lib/graphql/language/lexer.rl"
		begin
act = 7;		end
when 10 then
# line 58 "lib/graphql/language/lexer.rl"
		begin
act = 8;		end
when 11 then
# line 59 "lib/graphql/language/lexer.rl"
		begin
act = 9;		end
when 12 then
# line 60 "lib/graphql/language/lexer.rl"
		begin
act = 10;		end
when 13 then
# line 61 "lib/graphql/language/lexer.rl"
		begin
act = 11;		end
when 14 then
# line 62 "lib/graphql/language/lexer.rl"
		begin
act = 12;		end
when 15 then
# line 63 "lib/graphql/language/lexer.rl"
		begin
act = 13;		end
when 16 then
# line 64 "lib/graphql/language/lexer.rl"
		begin
act = 14;		end
when 17 then
# line 65 "lib/graphql/language/lexer.rl"
		begin
act = 15;		end
when 18 then
# line 66 "lib/graphql/language/lexer.rl"
		begin
act = 16;		end
when 19 then
# line 67 "lib/graphql/language/lexer.rl"
		begin
act = 17;		end
when 20 then
# line 68 "lib/graphql/language/lexer.rl"
		begin
act = 18;		end
when 21 then
# line 76 "lib/graphql/language/lexer.rl"
		begin
act = 26;		end
when 22 then
# line 83 "lib/graphql/language/lexer.rl"
		begin
act = 33;		end
when 23 then
# line 93 "lib/graphql/language/lexer.rl"
		begin
act = 37;		end
when 24 then
# line 69 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RCURLY)  end
		end
when 25 then
# line 70 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LCURLY)  end
		end
when 26 then
# line 71 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RPAREN)  end
		end
when 27 then
# line 72 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LPAREN)  end
		end
when 28 then
# line 73 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RBRACKET)  end
		end
when 29 then
# line 74 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LBRACKET)  end
		end
when 30 then
# line 75 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:COLON)  end
		end
when 31 then
# line 76 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_string(ts + 1, te - 1, meta)  end
		end
when 32 then
# line 77 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:VAR_SIGN)  end
		end
when 33 then
# line 78 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:DIR_SIGN)  end
		end
when 34 then
# line 79 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:ELLIPSIS)  end
		end
when 35 then
# line 80 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:EQUALS)  end
		end
when 36 then
# line 81 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:BANG)  end
		end
when 37 then
# line 82 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:PIPE)  end
		end
when 38 then
# line 85 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin 
      meta[:line] += 1
      meta[:col] = 1
     end
		end
when 39 then
# line 93 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 40 then
# line 51 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:INT)  end
		end
when 41 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:FLOAT)  end
		end
when 42 then
# line 83 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:IDENTIFIER)  end
		end
when 43 then
# line 90 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 44 then
# line 91 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 45 then
# line 93 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 46 then
# line 51 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:INT)  end
		end
when 47 then
# line 93 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 48 then
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
	when 26 then
	begin begin p = ((te))-1; end
 emit_string(ts + 1, te - 1, meta) end
	when 33 then
	begin begin p = ((te))-1; end
 emit_token.call(:IDENTIFIER) end
	when 37 then
	begin begin p = ((te))-1; end
 emit_token.call(:UNKNOWN_CHAR) end
end 
			end
# line 899 "lib/graphql/language/lexer.rb"
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
# line 919 "lib/graphql/language/lexer.rb"
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

# line 136 "lib/graphql/language/lexer.rl"

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
      UTF_8_REPLACE = -> (m) { [m[-4..-1].to_i(16)].pack('U'.freeze) }

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
