# frozen_string_literal: true
module GraphQL
  module Analysis
    # A query reducer for tracking both field usage and deprecated field usage.
    #
    # @example Logging field usage and deprecated field usage
    #   Schema.query_analyzers << GraphQL::Analysis::FieldUsage.new { |query, used_fields, used_deprecated_fields|
    #     puts "Used GraphQL fields: #{used_fields.join(', ')}"
    #     puts "Used deprecated GraphQL fields: #{used_deprecated_fields.join(', ')}"
    #   }
    #   Schema.execute(query_str)
    #   # Used GraphQL fields: Cheese.id, Cheese.fatContent, Query.cheese
    #   # Used deprecated GraphQL fields: Cheese.fatContent
    #
    class FieldUsage
      def initialize(&block)
        @field_usage_handler = block
      end

      def initial_value(query)
        {
          query: query,
          used_fields: Set.new,
          used_deprecated_fields: Set.new
        }
      end

      def call(memo, visit_type, irep_node)
        if irep_node.ast_node.is_a?(GraphQL::Language::Nodes::Field) && visit_type == :leave
          field = "#{irep_node.owner_type.name}.#{irep_node.definition.name}"
          memo[:used_fields] << field
          if irep_node.definition.deprecation_reason
            memo[:used_deprecated_fields] << field
          end
        end

        memo
      end

      def final_value(memo)
        @field_usage_handler.call(memo[:query], memo[:used_fields].to_a, memo[:used_deprecated_fields].to_a)
      end
    end
  end
end
