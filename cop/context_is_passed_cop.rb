# frozen_string_literal: true
require 'rubocop'

module Cop
  class ContextIsPassedCop < RuboCop::Cop::Cop
    MSG = <<-MSG
This method also accepts `context` as an argument. Pass it so that the returned value will reflect the current query, or use another method that isn't context-dependent.
MSG

    # These are already context-aware or else not query-related
    def_node_matcher :likely_query_specific_receiver?, "
      {
       (send _ {:query :context :warden :ctx :query_ctx :query_context})
       (ivar {:@query :@context :@warden})
       (send _ {:introspection_system})
      }
    "

    def_node_matcher :method_doesnt_receive_second_context_argument?, <<-MATCHER
      (send _ {:get_field :get_argument :get_type} _)
    MATCHER

    def_node_matcher :method_doesnt_receive_first_context_argument?, <<-MATCHER
      (send _ {:fields :argument :types :enum_values})
    MATCHER

    def on_send(node)
      if (
          method_doesnt_receive_second_context_argument?(node) ||
            method_doesnt_receive_first_context_argument?(node)
          ) && !likely_query_specific_receiver?(node.to_a[0])
        add_offense(node)
      end
    end
  end
end
