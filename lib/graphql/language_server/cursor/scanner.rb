# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class Cursor
      # Process the given text; return a {Cursor} with as much
      # data as we can get for the position at `line,column`.
      class Scanner
        def initialize(document_position:)
          @document_position = document_position
          @text = document_position.text
          @line = document_position.line
          @filename = document_position.filename
          @column = document_position.column
          @server = document_position.server
          @logger = document_position.server.logger
        end

        def cursor
          @cursor ||= find_cursor
        end

        private

        def find_cursor
          language_scope = LanguageScope.new(document_position: @document_position)

          if !language_scope.graphql_code?
            @logger.info("Out-of-scope cursor")
            return Cursor.out_of_scope
          end

          tokens = GraphQL.scan(@text)
          self_stack = SelfStack.new
          self_stack.stage(@server.type(:query))
          input_stack = InputStack.new
          var_def_state = VariableDef.new(logger: @logger)
          fragment_def_state = FragmentDef.new(logger: @logger)
          fragment_spread_state = FragmentSpread.new(logger: @logger)

          cursor_token = nil
          # statefully work through the tokens, track self_state,
          # and record the cursor token
          tokens.each do |token|
            @logger.info("Token: #{token.inspect}")
            # If we went _past_ the cursor, don't consume the next token.
            if token.line > @line || (token.line == @line && token.col > @column)
              @logger.info("NO CURSOR TOKEN")
              break
            end
            # Allow the state machines to consume this token:
            fragment_def_state.consume(token)
            fragment_spread_state.consume(token)
            var_def_state.consume(token)
            case token.name
            when :QUERY, :MUTATION, :SUBSCRIPTION
              key = token.name.to_s.downcase.to_sym
              self_stack.stage(@server.type(key))
            when :LCURLY
              self_stack.push_staged
              # Only push an input value if we're inside parens
              if input_stack.last
                input_stack.push_staged
              end
            when :RCURLY
              self_stack.pop
              input_stack.pop
            when :LPAREN
              self_stack.lock
              input_stack.push_staged
            when :RPAREN
              self_stack.unlock
              input_stack.pop
            when :IDENTIFIER
              self_type = self_stack.last
              input_type = input_stack.last
              @logger.debug("#{token.value} ?? (#{self_type&.name}, #{input_type&.name})")
              if self_type && (field = self_type.get_field(token.value))
                return_type_name = field.type.unwrap.name
                self_stack.stage(@server.type(return_type_name))
                field = self_type.fields[token.value]
                input_stack.stage(field)
              elsif input_type && (argument = input_type.arguments[token.value])
                input_type_name = argument.type.unwrap.name
                input_stack.stage(@server.type(input_type_name))
              elsif fragment_def_state.state == :type_name && (frag_type = @server.type(token.value))
                self_stack.stage(frag_type)
              end
            end

            # Check if this is the cursor_token
            if token.line == @line && ((token.col == @column) || ((token.col < @column) && (token.value.length > 0) && ((token.col + token.value.length) > @column)))
              @logger.info("Found cursor (#{@line},#{@line}): #{token.value}")
              cursor_token = token
              break
            end
          end

          self_type = self_stack.last
          input_type = input_stack.last
          @logger.info("Lasts: #{self_type.inspect}, #{input_type.inspect}")
          @logger.info("States: #{var_def_state.state.inspect}, #{fragment_def_state.state.inspect}, #{fragment_spread_state.state.inspect}")

          Cursor.new(
            current_type: self_type,
            current_input: input_type,
            current_token: cursor_token,
            var_def_state: var_def_state,
            fragment_def_state: fragment_def_state,
            fragment_spread_state: fragment_spread_state,
            root: self_type.nil? && !self_stack.locked? && self_stack.empty?,
          )
        end
      end
    end
  end
end
