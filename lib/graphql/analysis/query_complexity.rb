module GraphQL
  module Analysis
    # Calculate the complexity of a query, using {Field#complexity} values.
    #
    # @example Log the complexity of incoming queries
    #   MySchema.query_analyzers << GraphQL::AnalysisQueryComplexity.new do |query, complexity|
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
      # - `complexities_on_type` holds complexity scores for each type in an IRep node
      # - `skip_depth` increments for each skipped node, then decrements on the way out.
      #   While it's greater than `0`, we're visiting a skipped part of the query.
      def initial_value(query)
        {
          query: query,
          complexities_on_type: [TypeComplexity.new],
          skip_depth: 0,
        }
      end

      # Implement the query analyzer API
      def call(memo, visit_type, irep_node)
        if irep_node.ast_node.is_a?(GraphQL::Language::Nodes::Field)
          if visit_type == :enter
            if irep_node.skipped?
              memo[:skip_depth] += 1
            elsif memo[:skip_depth] == 0
              memo[:complexities_on_type].push(TypeComplexity.new)
            end
          else
            if memo[:skip_depth] > 0
              if irep_node.skipped?
                memo[:skip_depth] -= 1
              end
            else
              type_complexities = memo[:complexities_on_type].pop
              child_complexity = type_complexities.max_possible_complexity
              own_complexity = get_complexity(irep_node, memo[:query], child_complexity)
              memo[:complexities_on_type].last.merge(irep_node.definitions, own_complexity)
            end
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
        max_possible_complexity = 0
        irep_node.definitions.each do |type_defn, field_defn|
          defined_complexity = field_defn.complexity
          type_cpx = case defined_complexity
          when Proc
            args = query.arguments_for(irep_node, field_defn)
            defined_complexity.call(query.context, args, child_complexity)
          when Numeric
            defined_complexity + (child_complexity || 0)
          else
            raise("Invalid complexity: #{defined_complexity.inspect} on #{field_defn.name}")
          end

          if type_cpx > max_possible_complexity
            max_possible_complexity = type_cpx
          end
        end
        max_possible_complexity
      end

      # Selections on an object may apply differently depending on what is _actually_ returned by the resolve function.
      # Find the maximum possible complexity among those combinations.
      class TypeComplexity
        def initialize
          @types = Hash.new { |h, k| h[k] = 0 }
        end

        # Return the max possible complexity for types in this selection
        def max_possible_complexity
          max_complexity = 0

          @types.each do |type_defn, own_complexity|
            type_complexity = @types.reduce(0) do |memo, (other_type, other_complexity)|
              if types_overlap?(type_defn, other_type)
                memo + other_complexity
              else
                memo
              end
            end

            if type_complexity > max_complexity
              max_complexity = type_complexity
            end
          end
          max_complexity
        end

        # Store the complexity score for each of `types`
        def merge(definitions, complexity)
          definitions.each { |type_defn, field_defn| @types[type_defn] += complexity }
        end

        private
        # True if:
        # - type_1 is type_2
        # - type_1 is a member of type_2's possible types
        def types_overlap?(type_1, type_2)
          if type_1 == type_2
            true
          elsif type_2.kind.union?
            type_2.include?(type_1)
          elsif type_1.kind.object? && type_2.kind.interface?
            type_1.interfaces.include?(type_2)
          else
            false
          end
        end
      end
    end
  end
end
