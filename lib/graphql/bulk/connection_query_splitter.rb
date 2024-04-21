module GraphQL
  module Bulk
    class ConnectionQuerySplitter
      UnrolledConnectionQuery = Struct.new(:rollup_field_name, :unrolled_query)
      SplitConnectionQuery = Struct.new(:paginated_query, :unrolled_connection_queries)

      def initialize(connection_query, schema)
        @connection_query = connection_query
        @schema = schema
      end

      def split_query
        gql_query_document = GraphQL::Query.new(@schema, @connection_query.query_string).document

        result = handle_nested_connections(gql_query_document)
        paginated_query = handle_pagination_splitting(result[:base_query_without_nested_connections])

        SplitConnectionQuery.new(paginated_query, result[:unrolled_connection_queries])
      end

      private

      def handle_nested_connections(gql_query_document)
        connection_removal_visitor = Visitors::ConnectionRemovalVisitor.new(gql_query_document, depth: 2)
        base_query_document = connection_removal_visitor.visit

        unrolled_connection_queries = []
        connection_removal_visitor.connections.each do |connection|
          connection_document = Visitors::ConnectionNodeExtractionVisitor.new(gql_query_document, connection)
          unrolled_connection_queries << unroll_root_connection_query(connection_document.visit)
        end

        {
          unrolled_connection_queries: unrolled_connection_queries,
          base_query_without_nested_connections: base_query_document,
        }
      end

      def handle_pagination_splitting(gql_query_document)
        paginator = Visitors::AddPaginationToQueryVisitor.new(gql_query_document, root_connection_node(gql_query_document))
        paginator.visit.to_query_string
      end

      def unroll_root_connection_query(gql_query_document)
        root_connection_node = root_connection_node(gql_query_document)
        query_to_inject = extract_unrolled_query(root_connection_node)
        unrolled_query_string = "query UnrolledQuery($__appPlatformUniqueIdForUnrolling: EncodedId!) {#{root_connection_node.name.singularize}(id: $__appPlatformUniqueIdForUnrolling) { #{query_to_inject} }}"

        UnrolledConnectionQuery.new("#{@connection_query.path_string}.#{root_connection_node.name}", unrolled_query_string)
      end

      def root_connection_node(gql_query_document)
        root_connection_finder = Visitors::ConnectionRemovalVisitor.new(gql_query_document, depth: 1)
        root_connection_finder.visit
        root_connection_finder.connections.first.node
      end

      def extract_unrolled_query(root_connection_node)
        field_node = root_connection_node.selections.first

        if field_node.name == "nodes"
          # nodes -> <stuff I care about>
          return field_node.children.first.to_query_string
        end

        if field_node.name == "edges"
          # job -> edges -> node -> <stuff I care about>
          return field_node.children.first.children.first.to_query_string
        end

        raise Errors::BulkError, "#{root_connection_node.name} node does not have `nodes` or `edges` as it's first child"
      end
    end
  end
end
