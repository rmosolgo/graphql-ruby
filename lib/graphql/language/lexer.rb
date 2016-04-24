
# line 1 "lib/graphql/language/lexer.rl"

# line 65 "lib/graphql/language/lexer.rl"



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
	0, 1, 2, 1, 12, 1, 13, 1, 
	14, 1, 15, 1, 16, 1, 17, 1, 
	18, 1, 19, 1, 20, 1, 21, 1, 
	22, 1, 23, 1, 24, 1, 25, 1, 
	26, 1, 27, 1, 28, 1, 29, 1, 
	30, 1, 31, 1, 32, 1, 33, 2, 
	0, 1, 2, 3, 4, 2, 3, 5, 
	2, 3, 6, 2, 3, 7, 2, 3, 
	8, 2, 3, 9, 2, 3, 10, 2, 
	3, 11
]

class << self
	attr_accessor :_graphql_lexer_key_offsets
	private :_graphql_lexer_key_offsets, :_graphql_lexer_key_offsets=
end
self._graphql_lexer_key_offsets = [
	0, 0, 2, 4, 7, 9, 11, 15, 
	16, 17, 48, 51, 53, 55, 62, 64, 
	70, 77, 84, 93, 101, 109, 117, 125, 
	133, 141, 149, 157, 165, 173, 181, 189
]

class << self
	attr_accessor :_graphql_lexer_trans_keys
	private :_graphql_lexer_trans_keys, :_graphql_lexer_trans_keys=
end
self._graphql_lexer_trans_keys = [
	34, 92, 34, 92, 48, 49, 57, 48, 
	57, 48, 57, 43, 45, 48, 57, 46, 
	46, 9, 10, 13, 32, 33, 34, 35, 
	36, 40, 41, 44, 45, 46, 48, 58, 
	61, 64, 91, 93, 95, 102, 111, 116, 
	123, 125, 49, 57, 65, 90, 97, 122, 
	9, 32, 44, 34, 92, 10, 13, 43, 
	45, 46, 69, 101, 48, 57, 48, 57, 
	43, 45, 69, 101, 48, 57, 43, 45, 
	46, 69, 101, 48, 57, 95, 48, 57, 
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
	0, 2, 2, 1, 0, 0, 2, 1, 
	1, 25, 3, 2, 2, 5, 0, 4, 
	5, 1, 3, 2, 2, 2, 2, 2, 
	2, 2, 2, 2, 2, 2, 2, 2
]

class << self
	attr_accessor :_graphql_lexer_range_lengths
	private :_graphql_lexer_range_lengths, :_graphql_lexer_range_lengths=
end
self._graphql_lexer_range_lengths = [
	0, 0, 0, 1, 1, 1, 1, 0, 
	0, 3, 0, 0, 0, 1, 1, 1, 
	1, 3, 3, 3, 3, 3, 3, 3, 
	3, 3, 3, 3, 3, 3, 3, 3
]

class << self
	attr_accessor :_graphql_lexer_index_offsets
	private :_graphql_lexer_index_offsets, :_graphql_lexer_index_offsets=
end
self._graphql_lexer_index_offsets = [
	0, 0, 3, 6, 9, 11, 13, 17, 
	19, 21, 50, 54, 57, 60, 67, 69, 
	75, 82, 87, 94, 100, 106, 112, 118, 
	124, 130, 136, 142, 148, 154, 160, 166
]

class << self
	attr_accessor :_graphql_lexer_indicies
	private :_graphql_lexer_indicies, :_graphql_lexer_indicies=
end
self._graphql_lexer_indicies = [
	2, 3, 1, 4, 3, 1, 5, 7, 
	6, 8, 0, 10, 9, 11, 11, 8, 
	0, 12, 6, 13, 6, 14, 15, 15, 
	14, 16, 1, 17, 18, 19, 20, 14, 
	21, 22, 5, 23, 24, 25, 27, 28, 
	26, 29, 30, 31, 32, 33, 7, 26, 
	26, 6, 14, 14, 14, 34, 2, 3, 
	1, 36, 36, 17, 11, 11, 38, 39, 
	39, 8, 37, 8, 40, 11, 11, 39, 
	39, 10, 40, 11, 11, 38, 39, 39, 
	7, 37, 26, 26, 26, 26, 0, 26, 
	42, 43, 26, 26, 26, 41, 26, 44, 
	26, 26, 26, 41, 26, 45, 26, 26, 
	26, 41, 26, 46, 26, 26, 26, 41, 
	26, 47, 26, 26, 26, 41, 26, 48, 
	26, 26, 26, 41, 26, 49, 26, 26, 
	26, 41, 26, 50, 26, 26, 26, 41, 
	26, 51, 26, 26, 26, 41, 26, 52, 
	26, 26, 26, 41, 26, 53, 26, 26, 
	26, 41, 26, 54, 26, 26, 26, 41, 
	26, 55, 26, 26, 26, 41, 26, 56, 
	26, 26, 26, 41, 0
]

class << self
	attr_accessor :_graphql_lexer_trans_targs
	private :_graphql_lexer_trans_targs, :_graphql_lexer_trans_targs=
end
self._graphql_lexer_trans_targs = [
	9, 1, 9, 2, 11, 13, 0, 16, 
	14, 9, 15, 4, 8, 9, 10, 9, 
	9, 12, 9, 9, 9, 3, 7, 9, 
	9, 9, 17, 9, 9, 18, 28, 29, 
	9, 9, 9, 9, 9, 9, 5, 6, 
	9, 9, 19, 22, 20, 21, 17, 23, 
	24, 25, 26, 27, 17, 17, 30, 31, 
	17
]

class << self
	attr_accessor :_graphql_lexer_trans_actions
	private :_graphql_lexer_trans_actions, :_graphql_lexer_trans_actions=
end
self._graphql_lexer_trans_actions = [
	45, 0, 17, 0, 68, 50, 0, 50, 
	0, 43, 53, 0, 0, 23, 0, 29, 
	27, 0, 19, 7, 9, 0, 0, 15, 
	25, 21, 71, 11, 13, 0, 0, 0, 
	3, 5, 39, 35, 41, 31, 0, 0, 
	33, 37, 0, 0, 0, 0, 65, 0, 
	0, 0, 0, 0, 59, 56, 0, 0, 
	62
]

class << self
	attr_accessor :_graphql_lexer_to_state_actions
	private :_graphql_lexer_to_state_actions, :_graphql_lexer_to_state_actions=
end
self._graphql_lexer_to_state_actions = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 47, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0
]

class << self
	attr_accessor :_graphql_lexer_from_state_actions
	private :_graphql_lexer_from_state_actions, :_graphql_lexer_from_state_actions=
end
self._graphql_lexer_from_state_actions = [
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 1, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0, 
	0, 0, 0, 0, 0, 0, 0, 0
]

class << self
	attr_accessor :_graphql_lexer_eof_trans
	private :_graphql_lexer_eof_trans, :_graphql_lexer_eof_trans=
end
self._graphql_lexer_eof_trans = [
	0, 1, 1, 0, 1, 10, 1, 0, 
	0, 0, 35, 36, 37, 38, 41, 41, 
	38, 1, 42, 42, 42, 42, 42, 42, 
	42, 42, 42, 42, 42, 42, 42, 42
]

class << self
	attr_accessor :graphql_lexer_start
end
self.graphql_lexer_start = 9;
class << self
	attr_accessor :graphql_lexer_first_final
end
self.graphql_lexer_first_final = 9;
class << self
	attr_accessor :graphql_lexer_error
end
self.graphql_lexer_error = 0;

class << self
	attr_accessor :graphql_lexer_en_main
end
self.graphql_lexer_en_main = 9;


# line 86 "lib/graphql/language/lexer.rl"

      def self.run_lexer(query_string)
        data = query_string.unpack("c*")
        eof = data.length

        meta = {
          line: 1,
          col: 1,
          data: data,
          tokens: []
        }

        
# line 246 "lib/graphql/language/lexer.rb"
begin
	p ||= 0
	pe ||= data.length
	cs = graphql_lexer_start
	ts = nil
	te = nil
	act = 0
end

# line 99 "lib/graphql/language/lexer.rl"

        emit_token = -> (name) {
          emit(name, ts, te, meta)
        }

        
# line 263 "lib/graphql/language/lexer.rb"
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
	if cs == 0
		_goto_level = _out
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
			when 2 then
# line 1 "NONE"
		begin
ts = p
		end
# line 297 "lib/graphql/language/lexer.rb"
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
when 3 then
# line 1 "NONE"
		begin
te = p+1
		end
when 4 then
# line 35 "lib/graphql/language/lexer.rl"
		begin
act = 1;		end
when 5 then
# line 36 "lib/graphql/language/lexer.rl"
		begin
act = 2;		end
when 6 then
# line 37 "lib/graphql/language/lexer.rl"
		begin
act = 3;		end
when 7 then
# line 38 "lib/graphql/language/lexer.rl"
		begin
act = 4;		end
when 8 then
# line 39 "lib/graphql/language/lexer.rl"
		begin
act = 5;		end
when 9 then
# line 40 "lib/graphql/language/lexer.rl"
		begin
act = 6;		end
when 10 then
# line 48 "lib/graphql/language/lexer.rl"
		begin
act = 14;		end
when 11 then
# line 54 "lib/graphql/language/lexer.rl"
		begin
act = 20;		end
when 12 then
# line 41 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RCURLY)  end
		end
when 13 then
# line 42 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LCURLY)  end
		end
when 14 then
# line 43 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RPAREN)  end
		end
when 15 then
# line 44 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LPAREN)  end
		end
when 16 then
# line 45 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:RBRACKET)  end
		end
when 17 then
# line 46 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:LBRACKET)  end
		end
when 18 then
# line 47 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:COLON)  end
		end
when 19 then
# line 48 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_string(ts + 1, te - 1, meta)  end
		end
when 20 then
# line 49 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:VAR_SIGN)  end
		end
when 21 then
# line 50 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:DIR_SIGN)  end
		end
when 22 then
# line 51 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:ELLIPSIS)  end
		end
when 23 then
# line 52 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:EQUALS)  end
		end
when 24 then
# line 53 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin  emit_token.call(:BANG)  end
		end
when 25 then
# line 56 "lib/graphql/language/lexer.rl"
		begin
te = p+1
 begin 
      meta[:line] += 1
      meta[:col] = 1
     end
		end
when 26 then
# line 35 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:INT)  end
		end
when 27 then
# line 36 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:FLOAT)  end
		end
when 28 then
# line 48 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_string(ts + 1, te - 1, meta)  end
		end
when 29 then
# line 54 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  emit_token.call(:IDENTIFIER)  end
		end
when 30 then
# line 61 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 31 then
# line 62 "lib/graphql/language/lexer.rl"
		begin
te = p
p = p - 1; begin  meta[:col] += te - ts  end
		end
when 32 then
# line 35 "lib/graphql/language/lexer.rl"
		begin
 begin p = ((te))-1; end
 begin  emit_token.call(:INT)  end
		end
when 33 then
# line 1 "NONE"
		begin
	case act
	when 0 then
	begin	begin
		cs = 0
		_trigger_goto = true
		_goto_level = _again
		break
	end
end
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
end 
			end
# line 568 "lib/graphql/language/lexer.rb"
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
when 1 then
# line 1 "NONE"
		begin
act = 0
		end
# line 593 "lib/graphql/language/lexer.rb"
		end # to state action switch
	end
	if _trigger_goto
		next
	end
	if cs == 0
		_goto_level = _out
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

# line 105 "lib/graphql/language/lexer.rl"

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
