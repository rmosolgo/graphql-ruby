module GraphQL
  module Bulk
    class BaseQuerySplitter
      ConnectionQuery = Struct.new(:path_string, :query_string)
      SplitQuery = Struct.new(:base_query, :connection_queries)

      def initialize(query, schema)
        @query = query
        @schema = schema
      end

      def split_query
        gql_query_tree = add_type_name_fields

        connection_removal_visitor = Visitors::ConnectionRemovalVisitor.new(gql_query_tree.document)
        base_query_document = connection_removal_visitor.visit

        connection_queries = connection_removal_visitor.connections.map do |connection|
          connection_document = Visitors::ConnectionNodeExtractionVisitor.new(gql_query_tree.document, connection)
          query_document = connection_document.visit

          ConnectionQuery.new(
            connection.path.map{ |node| node.respond_to?(:name) ? node.name : "" }.join("."),
            query_document.to_query_string
          )
        end

        SplitQuery.new(
          base_query_document.to_query_string,
          connection_queries
        )
      end

      private

      def add_type_name_fields
        gql_query_tree = GraphQL::Query.new(@schema, @query)
        query_with_typename = Visitors::AddTypenameToQueryVisitor.new(gql_query_tree.document).visit
        GraphQL::Query.new(@schema, query_with_typename.to_query_string)
      end
    end
  end
end
