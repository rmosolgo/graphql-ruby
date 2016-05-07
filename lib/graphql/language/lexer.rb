
# line 1 "lib/graphql/language/lexer.rl"

# line 70 "lib/graphql/language/lexer.rl"



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
	12, 1, 13, 1, 14, 1, 15, 1, 
	16, 1, 17, 1, 18, 1, 19, 1, 
	20, 1, 21, 1, 22, 1, 23, 1, 
	24, 1, 25, 1, 26, 1, 27, 1, 
	28, 1, 29, 1, 30, 1, 31, 1, 
	32, 1, 33, 1, 34, 1, 35, 2, 
	2, 3, 2, 2, 4, 2, 2, 5, 
	2, 2, 6, 2, 2, 7, 2, 2, 
	8, 2, 2, 9, 2, 2, 10, 2, 
	2, 11
]

class << self
	attr_accessor :_graphql_lexer_key_offsets
	private :_graphql_lexer_key_offsets, :_graphql_lexer_key_offsets=
end
self._graphql_lexer_key_offsets = [
	0, 2, 4, 6, 8, 12, 13, 44, 
	47, 49, 51, 54, 61, 63, 69, 76, 
	77, 84, 93, 101, 109, 117, 125, 133, 
	141, 149, 157, 165, 173, 181, 189
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
	95, 102, 111, 116, 123, 125, 49, 57, 
	65, 90, 97, 122, 9, 32, 44, 34, 
	92, 10, 13, 48, 49, 57, 43, 45, 
	46, 69, 101, 48, 57, 48, 57, 43, 
	45, 69, 101, 48, 57, 43, 45, 46, 
	69, 101, 48, 57, 46, 95, 48, 57, 
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
	57, 65, 90, 97, 122, 95, 110, 48, 
	57, 65, 90, 97, 122, 95, 114, 48, 
	57, 65, 90, 97, 122, 95, 117, 48, 
	57, 65, 90, 97, 122, 95, 101, 48, 
	57, 65, 90, 97, 122, 0
]

class << self
	attr_accessor :_graphql_lexer_single_lengths
	private :_graphql_lexer_single_lengths, :_graphql_lexer_single_lengths=
end
self._graphql_lexer_single_lengths = [
	2, 2, 0, 0, 2, 1, 25, 3, 
	2, 2, 1, 5, 0, 4, 5, 1, 
	1, 3, 2, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2
]

class << self
	attr_accessor :_graphql_lexer_range_lengths
	private :_graphql_lexer_range_lengths, :_graphql_lexer_range_lengths=
end
self._graphql_lexer_range_lengths = [
	0, 0, 1, 1, 1, 0, 3, 0, 
	0, 0, 1, 1, 1, 1, 1, 0, 
	3, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3
]

class << self
	attr_accessor :_graphql_lexer_index_offsets
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
	0, 3, 6, 8, 10, 14, 16, 45, 
	49, 52, 55, 58, 65, 67, 73, 80, 
	82, 87, 94, 100, 106, 112, 118, 124, 
	130, 136, 142, 148, 154, 160, 166
]

class << self
	attr_accessor :_graphql_lexer_indicies
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
	2, 3, 1, 4, 3, 1, 5, 0, 
	7, 6, 8, 8, 5, 0, 10, 9, 
	12, 13, 13, 12, 14, 15, 16, 17, 
	18, 19, 12, 20, 21, 22, 24, 25, 
	26, 28, 29, 27, 30, 31, 32, 33, 
	34, 23, 27, 27, 11, 12, 12, 12, 
	35, 2, 3, 1, 36, 36, 16, 22, 
	23, 37, 8, 8, 39, 40, 40, 5, 
	38, 5, 41, 8, 8, 40, 40, 7, 
	41, 8, 8, 39, 40, 40, 23, 38, 
	42, 37, 27, 27, 27, 27, 0, 27, 
	44, 45, 27, 27, 27, 43, 27, 46, 
	27, 27, 27, 43, 27, 47, 27, 27, 
	27, 43, 27, 48, 27, 27, 27, 43, 
	27, 49, 27, 27, 27, 43, 27, 50, 
	27, 27, 27, 43, 27, 51, 27, 27, 
	27, 43, 27, 52, 27, 27, 27, 43, 
	27, 53, 27, 27, 27, 43, 27, 54, 
	27, 27, 27, 43, 27, 55, 27, 27, 
	27, 43, 27, 56, 27, 27, 27, 43, 
	27, 57, 27, 27, 27, 43, 27, 58, 
	27, 27, 27, 43, 0
]

class << self
	attr_accessor :_graphql_lexer_trans_targs
	private :_graphql_lexer_trans_targs, :_graphql_lexer_trans_targs=
end
self._graphql_lexer_trans_targs = [
	6, 0, 6, 1, 8, 12, 6, 13, 
	2, 6, 6, 6, 7, 6, 6, 8, 
	9, 6, 6, 6, 10, 15, 11, 14, 
	6, 6, 6, 16, 6, 6, 17, 27, 
	28, 6, 6, 6, 6, 6, 6, 3, 
	4, 6, 5, 6, 18, 21, 19, 20, 
	16, 22, 23, 24, 25, 26, 16, 16, 
	29, 30, 16
]

class << self
	attr_accessor :_graphql_lexer_trans_actions
	private :_graphql_lexer_trans_actions, :_graphql_lexer_trans_actions=
end
self._graphql_lexer_trans_actions = [
	53, 0, 21, 0, 73, 0, 49, 58, 
	0, 51, 27, 35, 0, 33, 31, 79, 
	0, 23, 11, 13, 0, 5, 55, 55, 
	19, 29, 25, 76, 15, 17, 0, 0, 
	0, 7, 9, 43, 45, 47, 37, 0, 
	0, 39, 0, 41, 0, 0, 0, 0, 
	70, 0, 0, 0, 0, 0, 64, 61, 
	0, 0, 67
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
	0, 0, 0, 0, 0, 0, 1, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
	0, 0, 0, 0, 0, 0, 3, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0
]

class << self
	attr_accessor :_graphql_lexer_eof_trans
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
	1, 1, 1, 7, 1, 10, 0, 36, 
	1, 37, 38, 39, 42, 42, 39, 38, 
	1, 44, 44, 44, 44, 44, 44, 44, 
	44, 44, 44, 44, 44, 44, 44
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


# line 91 "lib/graphql/language/lexer.rl"

      def self.run_lexer(query_string)
        data = query_string.unpack("c*")
        eof = data.length

        meta = {
          line: 1,
          col: 1,
          data: data,
          tokens: []
        }

        
# line 247 "lib/graphql/language/lexer.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = graphql_lexer_start
	ts = nil
	te = nil
	act = 0
end

# line 104 "lib/graphql/language/lexer.rl"

        emit_token = -> (name) {
          emit(name, ts, te, meta)
        }

        
# line 264 "lib/graphql/language/lexer.rb"
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
# line 294 "lib/graphql/language/lexer.rb"
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
	_trans = _graphql_lexer_indicies[_trans]
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
# line 38 "lib/graphql/language/lexer.rl"
		begin
act = 1;		end
when 4 then
# line 39 "lib/graphql/language/lexer.rl"
		begin
act = 2;		end
when 5 then
# line 40 "lib/graphql/language/lexer.rl"
		begin
act = 3;		end
when 6 then
# line 41 "lib/graphql/language/lexer.rl"
		begin
act = 4;		end
when 7 then
# line 42 "lib/graphql/language/lexer.rl"
		begin
act = 5;		end
when 8 then
# line 43 "lib/graphql/language/lexer.rl"
		begin
act = 6;		end
when 9 then
# line 51 "lib/graphql/language/lexer.rl"
		begin
act = 14;		end
when 10 then
# line 57 "lib/graphql/language/lexer.rl"
		begin
act = 20;		end
when 11 then
# line 67 "lib/graphql/language/lexer.rl"
		begin
act = 24;		end
when 12 then
# line 44 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RCURLY)  end
		end
when 13 then
# line 45 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LCURLY)  end
		end
when 14 then
# line 46 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RPAREN)  end
		end
when 15 then
# line 47 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LPAREN)  end
		end
when 16 then
# line 48 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RBRACKET)  end
		end
when 17 then
# line 49 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LBRACKET)  end
		end
when 18 then
# line 50 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:COLON)  end
		end
when 19 then
# line 51 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_string(ts + 1, te - 1, meta)  end
		end
when 20 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:VAR_SIGN)  end
		end
when 21 then
# line 53 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:DIR_SIGN)  end
		end
when 22 then
# line 54 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:ELLIPSIS)  end
		end
when 23 then
# line 55 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:EQUALS)  end
		end
when 24 then
# line 56 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:BANG)  end
		end
when 25 then
# line 59 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin 
      meta[:line] += 1
      meta[:col] = 1
     end
		end
when 26 then
# line 67 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 27 then
# line 38 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:INT)  end
		end
when 28 then
# line 39 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:FLOAT)  end
		end
when 29 then
# line 57 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:IDENTIFIER)  end
		end
when 30 then
# line 64 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 31 then
# line 65 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 32 then
# line 67 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 33 then
# line 38 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:INT)  end
		end
when 34 then
# line 67 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:UNKNOWN_CHAR)  end
		end
when 35 then
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
	when 14 then
	begin begin p = ((te))-1; end
 emit_string(ts + 1, te - 1, meta) end
	when 20 then
	begin begin p = ((te))-1; end
 emit_token.call(:IDENTIFIER) end
	when 24 then
	begin begin p = ((te))-1; end
 emit_token.call(:UNKNOWN_CHAR) end
end 
			end
# line 576 "lib/graphql/language/lexer.rb"
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
# line 596 "lib/graphql/language/lexer.rb"
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

# line 110 "lib/graphql/language/lexer.rl"

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
        replace_escaped_characters_in_place(value)

        meta[:tokens] << GraphQL::Language::Token.new(
          name: :STRING,
          value: value,
          line: meta[:line],
          col: meta[:col],
        )
        meta[:col] += te - ts
      end
    end
  end
end
