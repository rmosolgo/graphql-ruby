module GraphQL
  module Bulk
    module Errors
      class BulkError < StandardError; end

      class FragmentError < BulkError; end

      class QueryInvalidError < BulkError
        attr_reader :query

        def initialize(query)
          @query = query
          errors = query.static_errors
          message = errors.map(&:message).join(", ")

          super(message)
        end
      end
    end
  end
end
