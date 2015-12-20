module GraphQL
  # Store queries for a given schema on the server. Later, you can invoke them with
  # `operation_name`, `variables` and `context`.
  #
  # Since the operations will be run by name, they must be unique.
  #
  # @example Caching a query for a schema
  #   MySchema.cache_query(query_string)
  #
  # @example Executing a cached query
  #   MySchema.execute(nil, operation_name: op_name, variables: variables, context: ctx)
  #
  class QueryCache
    def initialize(schema)
      @schema = schema
      @operations = {}
    end

    # @return [Integer] the number of queries stored in the cache
    def size
      @operations.size
    end

    # Remove all cached queries
    def clear
      @operations.clear
    end

    # Cache the operations in this query string
    # @param [String] A GraphQL query for the provided {Schema}
    def add(query_string)
      query = GraphQL::Query.new(@schema, query_string)

      errors = query.validation_errors
      if errors.any?
        raise(InvalidQueryError.new(query.operations.keys, errors))
      elsif query.operations.keys.none?
        raise(OperationNameMissingError.new)
      else
        query.operations.each do |name, operation|
          if @operations.key?(name)
            raise DuplicateOperationNameError.new(name)
          else
            @operations[name] = query
          end
        end
      end
      nil
    end

    def execute(operation_name, context: nil, variables: {})
      query = @operations[operation_name]
      if query.nil?
        raise OperationMissingError.new(operation_name, @operations.keys)
      else
        query.execute(
          operation_name: operation_name,
          context: context,
          variables: variables,
        )
      end
    end

    class CacheError < StandardError; end

    class OperationNameMissingError < CacheError
      def initialize
        super("Can't cache query without an operation name (eg, 'getItem' in  'query getItem { ... }')")
      end
    end

    class DuplicateOperationNameError < CacheError
      def initialize(op_name)
        super("Tried to cache '#{op_name}', but it was already cached")
      end
    end

    class InvalidQueryError < CacheError
      def initialize(op_names, errors)
        error_str = errors.map { |e| stringify_error(e) }.join(", ")
        super("Can't cache operation(s) #{op_names.join(",")} with errors: #{error_str}")
      end

      private

      def stringify_error(err_hash)
        locations = err_hash["locations"].map { |p| "#{p["line"]}:#{p["column"]}" }
        "#{err_hash["message"]} (#{locations})"
      end
    end

    class OperationMissingError < CacheError
      def initialize(op_name, all_names)
        super("Tried to execute '#{op_name}', but it was not found (available: #{all_names.join(",")})")
      end
    end
  end
end
