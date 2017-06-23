# frozen_string_literal: true

module GraphQL
  class Schema
    class Template
      # @param erb_template [String]
      # @return [String] Reified GraphQL
      def self.run(erb_template, helpers: nil)
        template_class = self
        if helpers
          template_class = Class.new(template_class) {
            include helpers
          }
        end
        template_class.new(erb_template).run
      end

      # @param erb_template [String] GraphQL with embedded Ruby
      def initialize(erb_template)
        @erb_template = erb_template
        @result = ""
      end

      # @return [String] Rendered ERB
      def run
        ERB.new(@erb_template, 0, "", "@result").result(binding)
        @result
      end

      def connection(type_name)
        conn = type("#{type_name}Connection", edges: "[#{type_name}Edge!]!", pageInfo: "PageInfo!")
        edge = type("#{type_name}Edge", cursor: "ID!", node: "#{type_name}!")
        conn + "\n" + edge
      end

      def connects(fields)
        graphql = fields.map do |name, type|
          "#{name}(after: ID, before: ID, first: Int, last: Int): #{type}Connection!"
        end
        graphql.join("\n  ")
      end

      PAGE_INFO = "type PageInfo {\n  endCursor\n  }"
      def page_info
        type("PageInfo", {startCursor: "ID!", endCursor: "ID!", hasNextPage: "Boolean!", hasPreviousPage: "Boolean!"})
      end

      def type(name, fields)
        field_defns = fields
          .map { |name, returns| "\n  #{name}: #{returns}"}
          .sort
          .join

        "type #{name} {#{field_defns}\n}\n"
      end
    end
  end
end
