module GraphQL
  module Analysis
    # Calculate the complexity of a query, using {Field#complexity} values.
    #
    # @example Log the complexity of incoming queries
    #   MySchema.query_reducers << GraphQL::AnalysisQueryComplexity.new do |query, complexity|
    #     Rails.logger.info("Complexity: #{complexity}")
    #   end
    #
    class QueryComplexity
      # @yield [query, complexity] Called for each query analyzed by the schema, before executing it
      # @yieldparam query [GraphQL::Query] The query that was analyzed
      # @yieldparam complexity [Numeric] The complexity for this query
      def initialize(&block)
        @complexity_handler = block
      end

      # State for the query complexity calcuation:
      # - `query` is needed for variables, then passed to handler
      # - `complexities_on_type` holds complexity scores for nodes in the tree
      def initial_value(query)
        {
          query: query,
          complexities_on_type: [TypeComplexity.new],
        }
      end

      def call(memo, visit_type, irep_node)
        case irep_node.ast_node
        when GraphQL::Language::Nodes::Field
          if visit_type == :enter
            memo[:complexities_on_type].push(TypeComplexity.new)
          else
            type_complexities = memo[:complexities_on_type].pop
            child_complexity = type_complexities.max_possible_complexity
            own_complexity = get_complexity(irep_node, memo[:query], child_complexity)
            memo[:complexities_on_type].last.merge(irep_node.on_types, own_complexity)
          end
        end
        memo
      end

      # Send the query and complexity to the block
      # @return [Object, GraphQL::AnalysisError] Whatever the handler returns
      def final_value(reduced_value)
        total_complexity = reduced_value[:complexities_on_type].pop.max_possible_complexity
        @complexity_handler.call(reduced_value[:query], total_complexity)
      end

      private

      # Get a complexity value for a field,
      # by getting the number or calling its proc
      def get_complexity(irep_node, query, child_complexity)
        field_defn = irep_node.field
        defined_complexity = field_defn.complexity
        case defined_complexity
        when Proc
          # TODO: de-dup with query execution
          args = GraphQL::Query::LiteralInput.from_arguments(
            irep_node.ast_node.arguments,
            field_defn.arguments,
            query.variables
          )
          defined_complexity.call(query.context, args, child_complexity)
        when Numeric
          defined_complexity + (child_complexity || 0)
        else
          raise("Invalid complexity: #{defined_complexity.inspect} on #{field_defn.name}")
        end
      end

      class TypeComplexity
        def initialize
          @types = Hash.new { |h, k| h[k] = 0 }
          @total_complexity = 0
        end
        def max_possible_complexity
          @total_complexity + (@types.any? ? @types.values.max : 0)
        end

        def merge(types, complexity)
          if types.all? { |t| t.kind.object? }
            types.each { |t| @types[t] += complexity }
          else
            @total_complexity += complexity
          end
        end
      end
    end
  end
end
