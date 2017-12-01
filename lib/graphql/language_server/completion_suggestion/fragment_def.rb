# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class CompletionSuggestion
      # A state machine for tracking fragment definitions
      class FragmentDef
        attr_reader :state

        def initialize
          @state = nil
        end

        def reset
          @state = nil
        end

        def fragment
          transition(nil, :fragment)
        end

        def identifier(value:)
          transition(:fragment, :fragment_name) || transition(:on, :type_name)
        end

        def on
          # This accepts "fragment on TypeName" (no fragment name) to support graphql-client
          transition(:fragment_name, :on) || transition(:fragment, :on)
        end

        private

        # TODO dedup with VarDefState
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
