module GraphQL
  class Query
    class SerialExecution
      class ExecutionContext
        attr_reader :query, :strategy, :max_depth

        def initialize(query, strategy)
          @query = query
          @strategy = strategy
          @max_depth = query.max_depth
        end

        def depth_check(depth)
          return unless max_depth

          if depth > max_depth
            raise GraphQL::ExecutionError, 'Max query depth was exceeded'
          end
        end

        def get_type(type)
          @query.schema.types[type]
        end

        def get_fragment(name)
          @query.fragments[name]
        end

        def get_field(type, name)
          @query.schema.get_field(type, name)
        end

        def add_error(err)
          @query.context.errors << err
        end
      end
    end
  end
end
