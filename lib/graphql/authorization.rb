# frozen_string_literal: true
module GraphQL
  module Authorization
    module Analyzer
      module_function
      def initial_value(query)
        {
          schema: query.schema.class,
          context: query.context,
          inaccessible_nodes: [],
        }
      end

      def call(memo, visit_type, irep_node)
        if visit_type == :enter
          field = irep_node.definition
          if field
            schema = memo[:schema]
            ctx = memo[:context]
            next_field_accessible = schema.accessible?(field, ctx)
            if !next_field_accessible
              memo[:inaccessible_nodes] << irep_node
            else
              arg_accessible = true
              irep_node.arguments.argument_values.each do |name, arg_value|
                arg_accessible = schema.accessible?(arg_value.definition, ctx)
                if !arg_accessible
                  memo[:inaccessible_nodes] << irep_node
                  break
                end
              end
              if arg_accessible
                return_type = field.type.unwrap
                next_type_accessible = schema.accessible?(return_type, ctx)
                if !next_type_accessible
                  memo[:inaccessible_nodes] << irep_node
                end
              end
            end
          end
        end
        memo
      end

      def final_value(memo)
        nodes = memo[:inaccessible_nodes]
        if nodes.any?
          # TODO extract error hook
          # TODO default error message
          # Maybe make this a method on the Authorization plugin,
          # so it can be customized via inheritance
          GraphQL::AnalysisError.new("Some fields were unreachable ... ")
        else
          nil
        end
      end
    end
  end
end
