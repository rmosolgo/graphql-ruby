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
          irep_node.definitions.each do |type_defn, field_defn|
            field = "#{type_defn.name}.#{field_defn.name}"
            memo[:used_fields] << field
            memo[:used_deprecated_fields] << field if field_defn.deprecation_reason
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
