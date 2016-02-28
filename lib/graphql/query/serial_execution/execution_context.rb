module GraphQL
  class Query
    class SerialExecution
      class ExecutionContext
        attr_reader :query, :strategy

        def initialize(query, strategy)
          @query = query
          @strategy = strategy
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
