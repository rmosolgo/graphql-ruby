# frozen_string_literal: true
module GraphQL
  module Analysis
    # Calculate the complexity of a query, using {Field#complexity} values.
    #
    # @example Log the complexity of incoming queries
    #   MySchema.query_analyzers << GraphQL::Analysis::QueryComplexity.new do |query, complexity|
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
      # - `target` is passed to handler
      # - `complexities_on_type` holds complexity scores for each type in an IRep node
      def initial_value(target)
        {
          target: target,
          complexities_on_type: [TypeComplexity.new],
        }
      end

      # Implement the query analyzer API
      def call(memo, visit_type, irep_node)
        if irep_node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
          if visit_type == :enter
            memo[:complexities_on_type].push(TypeComplexity.new)
          else
            type_complexities = memo[:complexities_on_type].pop
            child_complexity = type_complexities.max_possible_complexity
            own_complexity = get_complexity(irep_node, child_complexity)
            memo[:complexities_on_type].last.merge(irep_node.owner_type, own_complexity)
          end
        end
        memo
      end

      # Send the query and complexity to the block
      # @return [Object, GraphQL::AnalysisError] Whatever the handler returns
      def final_value(reduced_value)
        total_complexity = reduced_value[:complexities_on_type].last.max_possible_complexity
        @complexity_handler.call(reduced_value[:target], total_complexity)
      end

      private

      # Get a complexity value for a field,
      # by getting the number or calling its proc
      def get_complexity(irep_node, child_complexity)
        field_defn = irep_node.definition
        defined_complexity = field_defn.complexity
        case defined_complexity
        when Proc
          defined_complexity.call(irep_node.query.context, irep_node.arguments, child_complexity)
        when Numeric
          defined_complexity + (child_complexity || 0)
        else
          raise("Invalid complexity: #{defined_complexity.inspect} on #{field_defn.name}")
        end
      end

      # Selections on an object may apply differently depending on what is _actually_ returned by the resolve function.
      # Find the maximum possible complexity among those combinations.
      class TypeComplexity
        def initialize
          @types = Hash.new(0)
        end

        # Return the max possible complexity for types in this selection
        def max_possible_complexity
          @types.each_value.max || 0
        end

        # Store the complexity for the branch on `type_defn`.
        # Later we will see if this is the max complexity among branches.
        def merge(type_defn, complexity)
          @types[type_defn] += complexity
        end
      end
    end
  end
end
