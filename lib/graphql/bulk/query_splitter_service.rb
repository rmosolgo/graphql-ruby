module GraphQL
    module Bulk
      class QuerySplitterService
        class << self
        def split(schema, query, debug: false)
            validate(schema, query)

            result = split_all_bulk_queries(schema, query)

            Debug.print_string(result) if debug

            result
          end

          def validate(schema, query)
            query = GraphQL::Query.new(schema, query)

            raise Errors::QueryInvalidError, query unless query.valid?
            raise Errors::FragmentError, "Bulk operations on a query with fragments is not supported" if query.fragments.any?
          end

          private

          def split_all_bulk_queries(schema, query)
            queries = {}

            base_splitter = BaseQuerySplitter.new(query, schema)
            base_results = base_splitter.split_query

            queries[:base] = base_results[:base_query]
            queries[:nested] = []

            base_results.connection_queries.each do |cq|
              connection_splitter = ConnectionQuerySplitter.new(cq, schema)
              connection_splitter_results = connection_splitter.split_query

              paginated = connection_splitter_results[:paginated_query]

              unrolled = connection_splitter_results.unrolled_connection_queries.map do |unrolled_query|
                {
                  rollup_field_name: unrolled_query.rollup_field_name,
                  queries: split_all_bulk_queries(schema, unrolled_query.unrolled_query),
                }
              end

              queries[:nested] << {
                path: cq.path_string,
                paginated: paginated,
                unrolled: unrolled,
              }
            end

            queries
          end
        end
      end
    end
  end
