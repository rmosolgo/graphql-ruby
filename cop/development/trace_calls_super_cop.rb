# frozen_string_literal: true
require 'rubocop'

module Cop
  module Development
    class TraceCallsSuperCop < RuboCop::Cop::Base
      extend RuboCop::Cop::AutoCorrector

      TRACE_HOOKS = [
        :analyze_multiplex,
        :analyze_query,
        :authorized,
        :authorized_lazy,
        :begin_analyze_multiplex,
        :begin_authorized,
        :begin_dataloader,
        :begin_dataloader_source,
        :begin_execute_field,
        :begin_multiplex,
        :begin_parse,
        :begin_resolve_type,
        :begin_validate,
        :dataloader_fiber_exit,
        :dataloader_fiber_resume,
        :dataloader_fiber_yield,
        :dataloader_spawn_execution_fiber,
        :dataloader_spawn_source_fiber,
        :end_analyze_multiplex,
        :end_authorized,
        :end_dataloader,
        :end_dataloader_source,
        :end_execute_field,
        :end_multiplex,
        :end_parse,
        :end_resolve_type,
        :end_validate,
        :execute_field,
        :execute_field_lazy,
        :execute_multiplex,
        :execute_query,
        :execute_query_lazy,
        :lex,
        :parse,
        :resolve_type,
        :resolve_type_lazy,
        :validate,
      ]

      MSG = "Trace methods should call `super` to pass control to other traces"

      def on_def(node)
        if TRACE_HOOKS.include?(node.method_name) && !node.each_descendant(:super, :zsuper).any?
          add_offense(node) do |corrector|
            offset = node.loc.column + 2
            corrector.insert_after(node.body.loc.expression, "\n#{' ' * offset}super")
          end
        end
      end
    end
  end
end
