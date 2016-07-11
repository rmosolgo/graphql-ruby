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
      # - `is_counting_complexity` is true during operations, but false during fragment definitions
      # - `complexity_stack` holds complexity scores for nodes in the tree
      # - `fragments_within_field` holds fragment type complexities for a given selection set
      def initial_value(query)
        {
          query: query,
          is_counting_complexity: false,
          complexity_stack: [
            # Document-level scores:
            [],
          ],
          fragments_within_field: [],
        }
      end

      def call(memo, visit_type, type_env, node, prev_node)
        case node
        when GraphQL::Language::Nodes::OperationDefinition
          if visit_type == :enter
            memo[:is_counting_complexity] = true
          else
            # Don't count complexity inside root fragment spreads,
            # since they'll be visited by the `follow_fragments`
            memo[:is_counting_complexity] = false
          end
        when GraphQL::Language::Nodes::Field
          if !memo[:is_counting_complexity]
            # We're inside a fragment defn, which is counted
            # when following fragments
          elsif visit_type == :enter
            memo[:complexity_stack].push([])
            memo[:fragments_within_field].push(FragmentComplexity.new)
          else
            fragment_complexity = memo[:fragments_within_field].pop.max_possible_complexity
            fields_complexity = memo[:complexity_stack].pop.reduce(&:+) || 0
            child_complexity = fragment_complexity + fields_complexity
            own_complexity = get_complexity(type_env.current_field_definition, node, memo[:query], child_complexity)
            memo[:complexity_stack].last.push(own_complexity)
          end
        when GraphQL::Language::Nodes::FragmentDefinition, GraphQL::Language::Nodes::InlineFragment
          if !memo[:is_counting_complexity]
            # We're inside a fragment defn, which is counted
            # when following fragments
          elsif visit_type == :enter
            memo[:complexity_stack].push([])
          else
            child_complexities = memo[:complexity_stack].pop
            child_complexity = child_complexities.reduce(&:+) || 0
            memo[:fragments_within_field].last[type_env.current_type_definition] += child_complexity
          end
        end
        memo
      end

      # Send the query and complexity to the block
      # @return [Object, GraphQL::AnalysisError] Whatever the handler returns
      def final_value(reduced_value)
        total_complexity = reduced_value[:complexity_stack].pop.reduce(&:+)
        @complexity_handler.call(reduced_value[:query], total_complexity)
      end

      private

      # Get a complexity value for a field,
      # by getting the number or calling its proc
      def get_complexity(field_defn, ast_node, query, child_complexity)
        defined_complexity = field_defn.complexity
        case defined_complexity
        when Proc
          args = GraphQL::Query::LiteralInput.from_arguments(
            ast_node.arguments,
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

      # Rule out mutually-exclusive fragments
      # - Find the max among object types (since an object can't be more than one type)
      # - Sum union/interfaces types (could this be improved?)
      class FragmentComplexity
        def initialize
          @type_complexities = Hash.new { |h, k| h[k] = 0 }
        end

        def [](type)
          @type_complexities[type]
        end

        def []=(type, complexity)
          @type_complexities[type] = complexity
        end

        def max_possible_complexity
          max_object_complexity = 0
          union_interface_complexity = 0
          @type_complexities.each do |type, complexity|
            if type.kind.object?
              if complexity > max_object_complexity
                max_object_complexity = complexity
              end
            else
              union_interface_complexity += complexity
            end
          end
          max_object_complexity + union_interface_complexity
        end
      end
    end
  end
end
