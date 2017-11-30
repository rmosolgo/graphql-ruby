# frozen_string_literal: true

module GraphQL
  class LanguageServer
    # This class responds with an array of `Item`s, based on
    # the cursor's `line` and `column` in `text` of `filename`.
    #
    # `server` has the system info, so it's provided here too.
    class CompletionSuggestion
      def initialize(filename:, text:, line:, column:, server:)
        @text = text
        @line = line
        @filename = filename
        @column = column
        @server = server
        @logger = server.logger
      end

      def items
        completion_items = []
        tokens = GraphQL.scan(@text)
        self_stack = SelfStack.new
        self_stack.stage(@server.type(:query))
        input_stack = InputStack.new
        var_def_state = VarDefState.new

        cursor_token = nil
        # statefully work through the tokens, track self_state,
        # and record the cursor token
        tokens.each do |token|
          @logger.info("Token: #{token.inspect}")

          case token.name
          when :QUERY, :MUTATION, :SUBSCRIPTION
            key = token.name.to_s.downcase.to_sym
            self_stack.stage(@server.type(key))
          when :LCURLY
            self_stack.push_staged
            input_stack.push_staged
          when :RCURLY
            self_stack.pop
            input_stack.pop
          when :LPAREN
            self_stack.lock
            input_stack.push_staged
          when :RPAREN
            var_def_state.end_defs
            self_stack.unlock
            input_stack.pop
          when :IDENTIFIER
            var_def_state.identifier(value: token.value)
            self_type = self_stack.last
            input_type = input_stack.last
            @logger.debug("#{token.value} ?? (#{self_type&.name}, #{input_type&.name}(#{input_type&.accepts(token.value)}))")
            if self_type && (field = self_type.get_field(token.value))
              return_type_name = field.type.unwrap.name
              self_stack.stage(@server.type(return_type_name))
              field = self_type.fields[token.value]
              input_stack.stage(field)
            elsif input_type && (input_type_name = input_type.accepts(token.value))
              input_stack.stage(@server.type(input_type_name))
            end
          when :VAR_SIGN
            var_def_state.var_sign
          when :EQUALS
            var_def_state.equals
          when :COLON
            var_def_state.colon
          when :BANG
            var_def_state.bang
          when :RBRACKET
            var_def_state.rbracket
          when *@@scalar_tokens
            var_def_state.default_value
          end

          # Check if this is the cursor_token
          if token.line == @line && ((token.col == @column) || ((token.col < @column) && (token.value.length > 0) && ((token.col + token.value.length) > @column)))
            @logger.info("Found cursor (#{@line},#{@line}): #{token.value}")
            cursor_token = token
            break
          elsif token.line >= @line && token.col > @column
            @logger.info("NO CURSOR TOKEN")
            break
          end
        end

        self_type = self_stack.last
        input_type = input_stack.last
        token_filter = TokenFilter.new(cursor_token)
        @logger.info("Lasts: #{self_type.inspect}, #{input_type.inspect}, #{var_def_state.state.inspect}")
        if cursor_token && @@scalar_tokens.include?(cursor_token.name)
          # pass; don't autocomplete these
        elsif var_def_state.state == :type_name
          @server.input_type_names.each do |input_type_name|
            if token_filter.match?(input_type_name)
              type = @server.type(input_type_name)
              completion_items << Item.from_input_type(type: type)
            end
          end
        elsif var_def_state.ended? && (var_def_state.state == :var_sign || var_def_state.state == :var_name)
          # TODO also filter var defs by type
          var_def_state.defined_variables.each do |var_name|
            if token_filter.value == "$" || token_filter.match?(var_name)
              type = var_def_state.defined_variable_types[var_name]
              completion_items << Item.from_variable(name: var_name, type: type)
            end
          end
        elsif input_type
          all_args = input_type.arguments
          all_args.each do |name, arg|
            completion_items << Item.from_argument(argument: arg)
          end
        elsif self_type.nil? && !self_stack.locked?
          [:query, :mutation, :subscription].each do |t|
            if (type = @server.type(t))
              label = t.to_s
              if token_filter.match?(label)
                completion_items << Item.from_root(root_type: type)
              end
            end
          end
          if token_filter.match?("fragment")
            completion_items << Item.from_fragment_token
          end
        elsif self_type
          self_type.fields.each do |name, f|
            if token_filter.match?(name)
              completion_items << Item.from_field(owner: self_type, field: f)
            end
          end
        end

        completion_items
      end

      private

      class Item
        attr_reader :label, :detail, :documentation, :kind, :insert_text

        def initialize(label:, detail:, insert_text: nil, documentation:, kind:)
          @label = label
          @detail = detail
          @insert_text = insert_text
          @documentation = documentation
          @kind = kind
        end

        def self.from_field(owner:, field:)
          self.new(
            label: field.name,
            detail: "#{owner.name}.#{field.name}",
            documentation: "#{field.description} (#{field.type.to_s})",
            kind: LSP::Constant::CompletionItemKind::FIELD,
          )
        end

        def self.from_fragment_token
          self.new(
            label: "fragment",
            detail: nil,
            documentation: "Add a new typed fragment",
            kind: LSP::Constant::CompletionItemKind::KEYWORD,
          )
        end

        def self.from_root(root_type:)
          self.new(
            label: root_type.name.downcase,
            detail: "#{root_type.name}!",
            documentation: root_type.description,
            kind: LSP::Constant::CompletionItemKind::KEYWORD,
          )
        end

        def self.from_argument(argument:)
          self.new(
            label: argument.name,
            insert_text: "#{argument.name}:",
            detail: argument.type.to_s,
            documentation: argument.description,
            kind: LSP::Constant::CompletionItemKind::FIELD,
          )
        end

        def self.from_variable(name:, type:)
          # TODO: list & non-null wrappers here
          # TODO include default values as documentation
          self.new(
            label: "$#{name}",
            insert_text: name,
            detail: type,
            documentation: "query variable",
            kind: LSP::Constant::CompletionItemKind::VARIABLE,
          )
        end

        def self.from_input_type(type:)
          self.new(
            label: type.name,
            detail: type.name,
            documentation: type.description,
            kind: LSP::Constant::CompletionItemKind::CLASS,
          )
        end
      end

      # Use a class variable to avoid warnings when reloading
      @@scalar_tokens = [:STRING, :FLOAT, :INT, :TRUE, :FALSE, :NULL]

      # A little state machine to track variable defs in the token stream
      class VarDefState
        attr_reader :state, :ended, :defined_variables, :defined_variable_types

        def initialize
          @state = nil
          @ended = false
          @defined_variables = []
          @defined_variable_types = {}
        end

        def ended?
          @ended
        end

        def end_defs
          @ended = true
          @state = nil
        end

        def var_sign
          # Always reset the beginning state
          @state = :var_sign
        end

        def identifier(value:)
          if transition(:var_sign, :var_name) && !@ended
            @defined_variables << value
          elsif transition(:colon, :type_name) && !@ended
            @defined_variable_types[@defined_variables.last] = value
          end
        end

        def colon
          transition(:var_name, :colon)
        end

        def equals
          transition(:type_name, :equals)
        end

        def bang
          if transition(:type_name, :type_name)
            @defined_variable_types[@defined_variables.last] += "!"
          end
        end

        def rbracket
          if transition(:type_name, :type_name)
            t = @defined_variable_types[@defined_variables.last]
            @defined_variable_types[@defined_variables.last] = "[#{t}]"
          end
        end

        def default_value
          transition(:equals, :default_value)
        end

        private

        # Returns falsy if no transition
        def transition(from_state, to_state)
          if @state == from_state
            @state = to_state
          else
            nil
          end
        end
      end

      class SelfStack
        def initialize
          @stack = []
          @next_self = nil
        end

        def stage(next_self)
          if !@locked
            @next_self = next_self
          end
        end

        def push_staged
          if !@locked
            push_self(@next_self)
            @next_self = nil
          end
        end

        # Use this when you enter an invalid scope,
        # namely, inside `(...)`, self_stack should be locked.
        def lock
          @locked = true
        end

        def unlock
          @locked = false
        end

        def locked?
          @locked
        end

        def pop
          if !@locked
            @stack.pop
          end
        end

        def last
          if @locked
            nil
          else
            @stack.last
          end
        end

        def empty?
          @stack.none?
        end

        private

        def push_self(next_self)
          @stack << next_self
        end
      end

      class InputStack < SelfStack
      end

      class TokenFilter
        # @return [String, nil]
        attr_reader :value
        # @param token [nil, GraphQL::Language::Token]
        def initialize(token)
          @token = token
          @value = token && token.value
          @uniq_chars = token && token.value.split.uniq
        end

        # @return [Boolean] true if this label matches the token
        def match?(label)
          @token.nil? || @uniq_chars.all? { |c| label.include?(c) }
        end
      end
    end
  end
end
