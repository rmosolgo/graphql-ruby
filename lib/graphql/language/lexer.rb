# frozen_string_literal: true

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
	attr_accessor :_graphql_lexer_actions 
	private :_graphql_lexer_actions, :_graphql_lexer_actions=
end
self._graphql_lexer_actions = [
0, 1, 0, 1, 1, 1, 2, 1, 3, 1, 27, 1, 28, 1, 29, 1, 30, 1, 31, 1, 32, 1, 33, 1, 34, 1, 35, 1, 36, 1, 37, 1, 38, 1, 39, 1, 40, 1, 41, 1, 42, 1, 43, 1, 44, 1, 45, 1, 46, 1, 47, 1, 48, 1, 49, 1, 50, 1, 51, 1, 52, 1, 53, 1, 54, 1, 55, 2, 2, 4, 2, 2, 5, 2, 2, 6, 2, 2, 7, 2, 2, 8, 2, 2, 9, 2, 2, 10, 2, 2, 11, 2, 2, 12, 2, 2, 13, 2, 2, 14, 2, 2, 15, 2, 2, 16, 2, 2, 17, 2, 2, 18, 2, 2, 19, 2, 2, 20, 2, 2, 21, 2, 2, 22, 2, 2, 23, 2, 2, 24, 2, 2, 25, 2, 2, 26, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_key_offsets 
	private :_graphql_lexer_key_offsets, :_graphql_lexer_key_offsets=
end
self._graphql_lexer_key_offsets = [
0, 0, 2, 11, 17, 23, 29, 35, 37, 38, 39, 41, 42, 43, 45, 47, 51, 52, 54, 63, 69, 75, 81, 87, 128, 131, 133, 134, 135, 136, 138, 139, 140, 142, 145, 152, 154, 160, 167, 168, 175, 183, 191, 199, 207, 215, 223, 231, 239, 248, 256, 264, 272, 280, 288, 296, 305, 313, 321, 329, 337, 345, 353, 361, 369, 377, 386, 394, 402, 410, 418, 426, 434, 442, 450, 459, 467, 475, 483, 491, 499, 507, 515, 523, 531, 539, 547, 555, 563, 571, 579, 587, 595, 603, 611, 619, 627, 635, 643, 652, 661, 669, 677, 685, 693, 701, 709, 717, 725, 733, 741, 749, 757, 765, 773, 781, 789, 798, 806, 814, 822, 830, 838, 846, 854, 862, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_trans_keys 
	private :_graphql_lexer_trans_keys, :_graphql_lexer_trans_keys=
end
self._graphql_lexer_trans_keys = [
34, 92, 34, 47, 92, 98, 102, 110, 114, 116, 117, 48, 57, 65, 90, 97, 122, 48, 57, 65, 90, 97, 122, 48, 57, 65, 90, 97, 122, 48, 57, 65, 90, 97, 122, 34, 92, 34, 34, 34, 92, 34, 34, 48, 57, 48, 57, 43, 45, 48, 57, 46, 34, 92, 34, 47, 92, 98, 102, 110, 114, 116, 117, 48, 57, 65, 90, 97, 122, 48, 57, 65, 90, 97, 122, 48, 57, 65, 90, 97, 122, 48, 57, 65, 90, 97, 122, 9, 10, 13, 32, 33, 34, 35, 36, 38, 40, 41, 44, 45, 46, 48, 58, 61, 64, 91, 93, 95, 100, 101, 102, 105, 109, 110, 111, 113, 115, 116, 117, 123, 124, 125, 49, 57, 65, 90, 97, 122, 9, 32, 44, 34, 92, 34, 34, 34, 34, 92, 34, 34, 10, 13, 48, 49, 57, 43, 45, 46, 69, 101, 48, 57, 48, 57, 43, 45, 69, 101, 48, 57, 43, 45, 46, 69, 101, 48, 57, 46, 95, 48, 57, 65, 90, 97, 122, 95, 105, 48, 57, 65, 90, 97, 122, 95, 114, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 99, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 105, 48, 57, 65, 90, 97, 122, 95, 118, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 110, 120, 48, 57, 65, 90, 97, 122, 95, 117, 48, 57, 65, 90, 97, 122, 95, 109, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 100, 48, 57, 65, 90, 97, 122, 95, 97, 114, 48, 57, 65, 90, 98, 122, 95, 108, 48, 57, 65, 90, 97, 122, 95, 115, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 97, 48, 57, 65, 90, 98, 122, 95, 103, 48, 57, 65, 90, 97, 122, 95, 109, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 109, 110, 48, 57, 65, 90, 97, 122, 95, 112, 48, 57, 65, 90, 97, 122, 95, 108, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 109, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 115, 48, 57, 65, 90, 97, 122, 95, 112, 116, 48, 57, 65, 90, 97, 122, 95, 117, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 114, 48, 57, 65, 90, 97, 122, 95, 102, 48, 57, 65, 90, 97, 122, 95, 97, 48, 57, 65, 90, 98, 122, 95, 99, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 117, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 97, 48, 57, 65, 90, 98, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 105, 48, 57, 65, 90, 97, 122, 95, 111, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 117, 48, 57, 65, 90, 97, 122, 95, 108, 48, 57, 65, 90, 97, 122, 95, 108, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 117, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 114, 48, 57, 65, 90, 97, 122, 95, 121, 48, 57, 65, 90, 97, 122, 95, 99, 117, 48, 57, 65, 90, 97, 122, 95, 97, 104, 48, 57, 65, 90, 98, 122, 95, 108, 48, 57, 65, 90, 97, 122, 95, 97, 48, 57, 65, 90, 98, 122, 95, 114, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 109, 48, 57, 65, 90, 97, 122, 95, 97, 48, 57, 65, 90, 98, 122, 95, 98, 48, 57, 65, 90, 97, 122, 95, 115, 48, 57, 65, 90, 97, 122, 95, 99, 48, 57, 65, 90, 97, 122, 95, 114, 48, 57, 65, 90, 97, 122, 95, 105, 48, 57, 65, 90, 97, 122, 95, 112, 48, 57, 65, 90, 97, 122, 95, 116, 48, 57, 65, 90, 97, 122, 95, 105, 48, 57, 65, 90, 97, 122, 95, 111, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 114, 121, 48, 57, 65, 90, 97, 122, 95, 117, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 112, 48, 57, 65, 90, 97, 122, 95, 101, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 95, 105, 48, 57, 65, 90, 97, 122, 95, 111, 48, 57, 65, 90, 97, 122, 95, 110, 48, 57, 65, 90, 97, 122, 34, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_single_lengths 
	private :_graphql_lexer_single_lengths, :_graphql_lexer_single_lengths=
end
self._graphql_lexer_single_lengths = [
0, 2, 9, 0, 0, 0, 0, 2, 1, 1, 2, 1, 1, 0, 0, 2, 1, 2, 9, 0, 0, 0, 0, 35, 3, 2, 1, 1, 1, 2, 1, 1, 2, 1, 5, 0, 4, 5, 1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3, 2, 2, 2, 2, 2, 2, 2, 2, 1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_range_lengths 
	private :_graphql_lexer_range_lengths, :_graphql_lexer_range_lengths=
end
self._graphql_lexer_range_lengths = [
0, 0, 0, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_index_offsets 
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
0, 0, 3, 13, 17, 21, 25, 29, 32, 34, 36, 39, 41, 43, 45, 47, 51, 53, 56, 66, 70, 74, 78, 82, 121, 125, 128, 130, 132, 134, 137, 139, 141, 144, 147, 154, 156, 162, 169, 171, 176, 182, 188, 194, 200, 206, 212, 218, 224, 231, 237, 243, 249, 255, 261, 267, 274, 280, 286, 292, 298, 304, 310, 316, 322, 328, 335, 341, 347, 353, 359, 365, 371, 377, 383, 390, 396, 402, 408, 414, 420, 426, 432, 438, 444, 450, 456, 462, 468, 474, 480, 486, 492, 498, 504, 510, 516, 522, 528, 535, 542, 548, 554, 560, 566, 572, 578, 584, 590, 596, 602, 608, 614, 620, 626, 632, 638, 645, 651, 657, 663, 669, 675, 681, 687, 693, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_targs 
	private :_graphql_lexer_cond_targs, :_graphql_lexer_cond_targs=
end
self._graphql_lexer_cond_targs = [
23, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 3, 23, 4, 4, 4, 23, 5, 5, 5, 23, 6, 6, 6, 23, 1, 1, 1, 23, 8, 10, 7, 9, 7, 27, 7, 11, 10, 7, 12, 7, 29, 7, 35, 23, 36, 23, 13, 13, 35, 23, 23, 23, 125, 18, 17, 17, 17, 17, 17, 17, 17, 17, 17, 19, 0, 20, 20, 20, 0, 21, 21, 21, 0, 22, 22, 22, 0, 17, 17, 17, 0, 24, 23, 23, 24, 23, 25, 32, 23, 23, 23, 23, 24, 33, 38, 34, 23, 23, 23, 23, 23, 39, 40, 48, 55, 65, 83, 90, 93, 94, 98, 116, 121, 23, 23, 23, 37, 39, 39, 23, 24, 24, 24, 23, 26, 2, 1, 7, 23, 28, 23, 23, 23, 30, 10, 7, 31, 7, 27, 7, 23, 23, 32, 34, 37, 23, 13, 13, 14, 15, 15, 35, 23, 35, 23, 13, 13, 15, 15, 36, 23, 13, 13, 14, 15, 15, 37, 23, 16, 23, 39, 39, 39, 39, 23, 39, 41, 39, 39, 39, 23, 39, 42, 39, 39, 39, 23, 39, 43, 39, 39, 39, 23, 39, 44, 39, 39, 39, 23, 39, 45, 39, 39, 39, 23, 39, 46, 39, 39, 39, 23, 39, 47, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 49, 51, 39, 39, 39, 23, 39, 50, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 52, 39, 39, 39, 23, 39, 53, 39, 39, 39, 23, 39, 54, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 56, 59, 39, 39, 39, 23, 39, 57, 39, 39, 39, 23, 39, 58, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 60, 39, 39, 39, 23, 39, 61, 39, 39, 39, 23, 39, 62, 39, 39, 39, 23, 39, 63, 39, 39, 39, 23, 39, 64, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 66, 74, 39, 39, 39, 23, 39, 67, 39, 39, 39, 23, 39, 68, 39, 39, 39, 23, 39, 69, 39, 39, 39, 23, 39, 70, 39, 39, 39, 23, 39, 71, 39, 39, 39, 23, 39, 72, 39, 39, 39, 23, 39, 73, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 75, 77, 39, 39, 39, 23, 39, 76, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 78, 39, 39, 39, 23, 39, 79, 39, 39, 39, 23, 39, 80, 39, 39, 39, 23, 39, 81, 39, 39, 39, 23, 39, 82, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 84, 39, 39, 39, 23, 39, 85, 39, 39, 39, 23, 39, 86, 39, 39, 39, 23, 39, 87, 39, 39, 39, 23, 39, 88, 39, 39, 39, 23, 39, 89, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 91, 39, 39, 39, 23, 39, 92, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 95, 39, 39, 39, 23, 39, 96, 39, 39, 39, 23, 39, 97, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 99, 106, 39, 39, 39, 23, 39, 100, 103, 39, 39, 39, 23, 39, 101, 39, 39, 39, 23, 39, 102, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 104, 39, 39, 39, 23, 39, 105, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 107, 39, 39, 39, 23, 39, 108, 39, 39, 39, 23, 39, 109, 39, 39, 39, 23, 39, 110, 39, 39, 39, 23, 39, 111, 39, 39, 39, 23, 39, 112, 39, 39, 39, 23, 39, 113, 39, 39, 39, 23, 39, 114, 39, 39, 39, 23, 39, 115, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 117, 119, 39, 39, 39, 23, 39, 118, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 120, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 39, 122, 39, 39, 39, 23, 39, 123, 39, 39, 39, 23, 39, 124, 39, 39, 39, 23, 39, 39, 39, 39, 39, 23, 17, 0, 0, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 17, 18, 19, 20, 21, 22, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 125, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_cond_actions 
	private :_graphql_lexer_cond_actions, :_graphql_lexer_cond_actions=
end
self._graphql_lexer_cond_actions = [
23, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 63, 0, 0, 0, 63, 0, 0, 0, 63, 0, 0, 0, 63, 0, 0, 0, 63, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 130, 0, 0, 65, 70, 61, 0, 0, 0, 65, 31, 63, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 41, 41, 0, 35, 5, 0, 27, 39, 15, 13, 0, 0, 5, 67, 21, 33, 29, 19, 17, 133, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 11, 37, 9, 67, 133, 133, 43, 0, 0, 0, 57, 127, 0, 0, 0, 49, 0, 51, 25, 51, 130, 0, 0, 130, 0, 0, 0, 55, 55, 0, 67, 67, 59, 0, 0, 0, 0, 0, 0, 45, 0, 47, 0, 0, 0, 0, 70, 47, 0, 0, 0, 0, 0, 67, 45, 0, 59, 133, 133, 133, 133, 65, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 124, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 118, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 106, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 82, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 76, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 109, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 121, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 112, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 91, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 85, 133, 133, 133, 53, 133, 73, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 88, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 100, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 97, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 94, 133, 133, 133, 53, 133, 0, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 79, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 103, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 0, 133, 133, 133, 53, 133, 115, 133, 133, 133, 53, 0, 0, 0, 63, 63, 63, 63, 63, 63, 65, 65, 65, 65, 65, 65, 65, 61, 65, 63, 0, 0, 0, 0, 0, 0, 0, 57, 59, 49, 51, 51, 51, 51, 51, 55, 59, 45, 47, 47, 45, 59, 65, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 53, 0, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions 
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions 
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0 , 
]

class << self
	attr_accessor :_graphql_lexer_eof_trans 
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
696, 697, 698, 699, 700, 701, 702, 703, 704, 705, 706, 707, 708, 709, 710, 711, 712, 713, 714, 715, 716, 717, 718, 719, 720, 721, 722, 723, 724, 725, 726, 727, 728, 729, 730, 731, 732, 733, 734, 735, 736, 737, 738, 739, 740, 741, 742, 743, 744, 745, 746, 747, 748, 749, 750, 751, 752, 753, 754, 755, 756, 757, 758, 759, 760, 761, 762, 763, 764, 765, 766, 767, 768, 769, 770, 771, 772, 773, 774, 775, 776, 777, 778, 779, 780, 781, 782, 783, 784, 785, 786, 787, 788, 789, 790, 791, 792, 793, 794, 795, 796, 797, 798, 799, 800, 801, 802, 803, 804, 805, 806, 807, 808, 809, 810, 811, 812, 813, 814, 815, 816, 817, 818, 819, 820, 821, 0 , 
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
		_klen= 0
		;
		_trans = 0;
		_keys= 0
		;
		_acts= 0
		;
		_nacts= 0
		;
		__have= 0
		;
		while ( p != pe || p == eof  )
			begin
				_acts = _graphql_lexer_from_state_actions[cs] ;
				_nacts = _graphql_lexer_actions[_acts ];
				_acts += 1;
				while ( _nacts > 0  )
					begin
						case  _graphql_lexer_actions[_acts ] 
						when -2 then
						begin
						end
						when 1  then
						begin
							begin
								begin
									ts = p;
									
								end
								
							end
							
							
						end
					end
					_nacts -= 1;
					_acts += 1;
					
				end
				
			end
			if ( p == eof  )
				begin
					if ( _graphql_lexer_eof_trans[cs] > 0  )
						begin
							_trans = _graphql_lexer_eof_trans[cs] - 1;
							
						end
						
					end
					
				end
				
				else
				begin
					_keys = _graphql_lexer_key_offsets[cs] ;
					_trans = _graphql_lexer_index_offsets[cs];
					_klen = _graphql_lexer_single_lengths[cs];
					__have = 0;
					if ( _klen > 0  )
						begin
							_lower = _keys;
							_upper = _keys + _klen - 1;
							_mid= 0
							;
							while ( true  )
								begin
									if ( _upper < _lower  )
										begin
											_keys += _klen;
											_trans += _klen;
											break;
											
										end
										
									end
									_mid = _lower + ((_upper-_lower) >> 1);
									if ( ( data[p ].ord) < _graphql_lexer_trans_keys[_mid ] )
										_upper = _mid - 1;
										
										elsif ( ( data[p ].ord) > _graphql_lexer_trans_keys[_mid ] )
										_lower = _mid + 1;
										
										else
										begin
											__have = 1;
											_trans += (_mid - _keys);
											break;
											
										end
										
									end
									
								end
								
							end
							
						end
						
					end
					_klen = _graphql_lexer_range_lengths[cs];
					if ( __have == 0 && _klen > 0  )
						begin
							_lower = _keys;
							_upper = _keys + (_klen<<1) - 2;
							_mid= 0
							;
							while ( true  )
								begin
									if ( _upper < _lower  )
										begin
											_trans += _klen;
											break;
											
										end
										
									end
									_mid = _lower + (((_upper-_lower) >> 1) & ~1);
									if ( ( data[p ].ord) < _graphql_lexer_trans_keys[_mid ] )
										_upper = _mid - 2;
										
										elsif ( ( data[p ].ord) > _graphql_lexer_trans_keys[_mid + 1 ] )
										_lower = _mid + 2;
										
										else
										begin
											_trans += ((_mid - _keys)>>1);
											break;
											
										end
										
									end
									
								end
								
							end
							
						end
						
					end
					
				end
				
			end
			cs = _graphql_lexer_cond_targs[_trans];
			if ( _graphql_lexer_cond_actions[_trans] != 0  )
				begin
					_acts = _graphql_lexer_cond_actions[_trans] ;
					_nacts = _graphql_lexer_actions[_acts ];
					_acts += 1;
					while ( _nacts > 0  )
						begin
							case  _graphql_lexer_actions[_acts ] 
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
							when 3  then
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
										act = 2;
										
									end
									
								end
								
							end
							when 5  then
							begin
								begin
									begin
										act = 3;
										
									end
									
								end
								
							end
							when 6  then
							begin
								begin
									begin
										act = 4;
										
									end
									
								end
								
							end
							when 7  then
							begin
								begin
									begin
										act = 5;
										
									end
									
								end
								
							end
							when 8  then
							begin
								begin
									begin
										act = 6;
										
									end
									
								end
								
							end
							when 9  then
							begin
								begin
									begin
										act = 7;
										
									end
									
								end
								
							end
							when 10  then
							begin
								begin
									begin
										act = 8;
										
									end
									
								end
								
							end
							when 11  then
							begin
								begin
									begin
										act = 9;
										
									end
									
								end
								
							end
							when 12  then
							begin
								begin
									begin
										act = 10;
										
									end
									
								end
								
							end
							when 13  then
							begin
								begin
									begin
										act = 11;
										
									end
									
								end
								
							end
							when 14  then
							begin
								begin
									begin
										act = 12;
										
									end
									
								end
								
							end
							when 15  then
							begin
								begin
									begin
										act = 13;
										
									end
									
								end
								
							end
							when 16  then
							begin
								begin
									begin
										act = 14;
										
									end
									
								end
								
							end
							when 17  then
							begin
								begin
									begin
										act = 15;
										
									end
									
								end
								
							end
							when 18  then
							begin
								begin
									begin
										act = 16;
										
									end
									
								end
								
							end
							when 19  then
							begin
								begin
									begin
										act = 17;
										
									end
									
								end
								
							end
							when 20  then
							begin
								begin
									begin
										act = 18;
										
									end
									
								end
								
							end
							when 21  then
							begin
								begin
									begin
										act = 19;
										
									end
									
								end
								
							end
							when 22  then
							begin
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
										act = 21;
										
									end
									
								end
								
							end
							when 24  then
							begin
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
										act = 30;
										
									end
									
								end
								
							end
							when 26  then
							begin
								begin
									begin
										act = 38;
										
									end
									
								end
								
							end
							when 27  then
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
							when 28  then
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
							when 29  then
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
							when 30  then
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
							when 31  then
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
							when 32  then
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
							when 33  then
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
							when 34  then
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
							when 36  then
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
							when 37  then
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
							when 38  then
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
							when 39  then
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
							when 40  then
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
							when 41  then
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
							when 42  then
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
							when 43  then
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
							when 44  then
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
							when 45  then
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
							when 46  then
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
							when 47  then
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
							when 48  then
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
							when 49  then
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
							when 50  then
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
							when 51  then
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
							when 52  then
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
							when 53  then
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
							when 54  then
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
							when 55  then
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
					end
					_nacts -= 1;
					_acts += 1;
					
				end
				
			end
			
		end
		
	end
	if ( p == eof  )
		begin
			if ( cs >= 23  )
				break;
				
			end
			
		end
		
		else
		begin
			_acts = _graphql_lexer_to_state_actions[cs] ;
			_nacts = _graphql_lexer_actions[_acts ];
			_acts += 1;
			while ( _nacts > 0  )
				begin
					case  _graphql_lexer_actions[_acts ] 
					when -2 then
					begin
					end
					when 0  then
					begin
						begin
							begin
								ts = 0;
								
							end
							
						end
						
						
					end
				end
				_nacts -= 1;
				_acts += 1;
				
			end
			
		end
		if ( cs != 0  )
			begin
				p += 1;
				next;
				
			end
			
		end
		
	end
	
end
break;

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
