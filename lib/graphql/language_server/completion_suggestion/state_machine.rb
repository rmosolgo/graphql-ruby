# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class CompletionSuggestion
      # These state machines:
      # - "Consume" tokens by perhaps modifying `.state`, storing values
      # - May be left in _any_ state at any time, since the token stream might not be valid
      # - Should be prepared to reset in some cases (if they were previously left invalid)
      #
      # Define methods corresponding to token types to respond to tokens and make transitions
      # @api private
      class StateMachine
        # Add to this list as we need to respond to other token types
        TOKEN_NAMES = [
          # Keywords
          :QUERY, :MUTATION, :SUBSCRIPTION, :FRAGMENT, :ON,
          # Open-and-close punctuation
          :RCURLY, :LCURLY, :RPAREN, :LPAREN, :RBRACKET, :LBRACKET,
          # One-off punctuation
          :VAR_SIGN, :EQUALS, :COLON, :BANG,
          # Values
          :IDENTIFIER, :STRING, :FLOAT, :INT, :TRUE, :FALSE, :NULL,
        ]
        # Convert each token into a downcased symbol
        METHOD_NAMES = TOKEN_NAMES.reduce({}) { |m, t| m[t] = t.to_s.downcase.to_sym; m }

        # @return [Symbol, nil]
        attr_reader :state

        def initialize
          @state = nil
        end

        def consume(token)
          method_name = METHOD_NAMES[token.name]
          if method_name && respond_to?(method_name)
            public_send(method_name, token)
          end
        end

        # Override this to do other reset logic
        def reset(_token = nil)
          @state = nil
        end

        def self.reset(*method_names)
          reset_method = instance_method(:reset)
          method_names.each { |m| define_method(m, reset_method)}
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
    end
  end
end
