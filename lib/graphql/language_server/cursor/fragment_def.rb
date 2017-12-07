# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class Cursor
      # A state machine for tracking fragment definitions
      class FragmentDef < Cursor::StateMachine
        reset :lcurly, :rcurly, :lparen, :rparen

        def fragment(_token)
          transition(nil, :fragment)
        end

        def identifier(_token)
          transition(:fragment, :fragment_name) || transition(:on, :type_name)
        end

        def on(_token)
          # This accepts "fragment on TypeName" (no fragment name) to support graphql-client
          transition(:fragment_name, :on) || transition(:fragment, :on)
        end
      end
    end
  end
end
