module GraphQL
  module Language
    module Generation
      def self.generate(node)
        node.to_query_string
      end
    end
  end
end
