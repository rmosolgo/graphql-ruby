module GraphQL
  module Analysis
    class QueryComplexity
      def initialize(&block)
        @complexity_handler = block
      end

      def initial_value(query)
        {
          query: query,
          is_counting_complexity: false,
          complexity_stack: [
            # Document-level scores:
            [],
          ],
        }
      end

      def call(memo, visit_type, type_env, node, prev_node)
        case node
        when GraphQL::Language::Nodes::OperationDefinition
          if visit_type == :enter
            memo[:is_counting_complexity] = true
          else
            memo[:is_counting_complexity] = false
          end
        when GraphQL::Language::Nodes::Field
          if !memo[:is_counting_complexity]
            # We're inside a fragment defn, which is counted
            # when following fragments
          elsif visit_type == :enter
            memo[:complexity_stack].push([])
          else
            child_complexity = memo[:complexity_stack].pop.reduce(&:+)
            own_complexity = get_complexity(type_env.current_field_definition, node, memo[:query], child_complexity)
            memo[:complexity_stack].last.push(own_complexity)
          end
        end
        memo
      end

      def final_value(reduced_value)
        total_complexity = reduced_value[:complexity_stack].pop.reduce(&:+)
        @complexity_handler.call(total_complexity)
      end

      private

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
    end
  end
end
