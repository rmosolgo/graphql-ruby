# frozen_string_literal: true
module GraphQL
  class LanguageServer
    class CompletionSuggestion
      # A state machine for tracking variable definitions
      class VariableDef < CompletionSuggestion::StateMachine
        attr_reader :ended, :defined_variables, :defined_variable_types

        def initialize
          super
          @ended = false
          @defined_variables = []
          @defined_variable_types = {}
        end

        def ended?
          @ended
        end

        def rparen(_token)
          @ended = true
          @state = nil
        end

        def var_sign(_token)
          # Always reset the beginning state
          @state = :var_sign
        end

        def identifier(token)
          if transition(:var_sign, :var_name) && !@ended
            @defined_variables << token.value
          elsif transition(:colon, :type_name) && !@ended
            @defined_variable_types[@defined_variables.last] = token.value
          end
        end

        def colon(_token)
          transition(:var_name, :colon)
        end

        def equals(_token)
          transition(:type_name, :equals)
        end

        def bang(_token)
          if transition(:type_name, :type_name)
            @defined_variable_types[@defined_variables.last] += "!"
          end
        end

        def rbracket(_token)
          if transition(:type_name, :type_name)
            t = @defined_variable_types[@defined_variables.last]
            @defined_variable_types[@defined_variables.last] = "[#{t}]"
          end
        end

        def default_value(_token)
          transition(:equals, :default_value)
        end

        # When we find a scalar, treat it as a default value
        alias :string :default_value
        alias :float :default_value
        alias :int :default_value
        alias :true :default_value
        alias :false :default_value
        alias :null :default_value
      end
    end
  end
end
