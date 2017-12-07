# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class Cursor
      # A state machine for tracking fragment definitions
      class FragmentSpread < Cursor::StateMachine
        reset :lcurly, :rcurly

        def ellipsis(_token)
          transition(nil, :ellipsis)
        end

        def identifier(_token)
          transition(:on, :type_name)
        end

        def on(_token)
          transition(:ellipsis, :on)
        end
      end
    end
  end
end
