# frozen_string_literal: true
module GraphQL
  module Analysis
    # Calculate the complexity of a query, using {Field#complexity} values.
    module AST
      class QueryComplexity < Analyzer
        # State for the query complexity calcuation:
        # - `complexities_on_type` holds complexity scores for each type in an IRep node
        def initialize(query)
          super
          @complexities_on_type = [TypeComplexity.new]
        end

        # Overide this method to use the complexity result
        def result
          max_possible_complexity
        end

        def on_enter_field(node, parent, visitor)
          # We don't want to visit fragment definitions,
          # we'll visit them when we hit the spreads instead
          return if visitor.visiting_fragment_definition?
          return if visitor.skipping?

          @complexities_on_type.push(TypeComplexity.new)
        end

        def on_leave_field(node, parent, visitor)
          # We don't want to visit fragment definitions,
          # we'll visit them when we hit the spreads instead
          return if visitor.visiting_fragment_definition?
          return if visitor.skipping?

          type_complexities = @complexities_on_type.pop
          child_complexity = type_complexities.max_possible_complexity
          own_complexity = get_complexity(node, visitor.field_definition, child_complexity, visitor)

          parent_type = visitor.parent_type_definition
          possible_types = if parent_type.kind.abstract?
            query.possible_types(parent_type)
          else
            [parent_type]
          end

          key = selection_key(visitor.response_path, visitor.query)

          possible_types.each do |type|
            @complexities_on_type.last.merge(type, key, own_complexity)
          end
        end

        def on_enter_fragment_spread(node, _, visitor)
          visitor.enter_fragment_spread_inline(node)
        end

        def on_leave_fragment_spread(node, _, visitor)
          visitor.leave_fragment_spread_inline(node)
        end

        # @return [Integer]
        def max_possible_complexity
          @complexities_on_type.last.max_possible_complexity
        end

        private

        def selection_key(response_path, query)
          # We add the query object id to support multiplex queries
          # even if they have the same response path, they should
          # always be added.
          response_path.join(".") + "-#{query.object_id}"
        end

        # Get a complexity value for a field,
        # by getting the number or calling its proc
        def get_complexity(ast_node, field_defn, child_complexity, visitor)
        # Return if we've visited this response path before (not counting duplicates)
          defined_complexity = field_defn.complexity

          # TODO no graphql_definition, see also directive_checks.rb
          arguments = visitor.arguments_for(ast_node, field_defn.graphql_definition)

          case defined_complexity
          when Proc
            defined_complexity.call(query.context, arguments, child_complexity)
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
            @types = Hash.new { |h, k| h[k] = {} }
          end

          # Return the max possible complexity for types in this selection
          def max_possible_complexity
            @types.map do |type, fields|
              fields.values.inject(:+)
            end.max
          end

          # Store the complexity for the branch on `type_defn`.
          # Later we will see if this is the max complexity among branches.
          def merge(type_defn, key, complexity)
            @types[type_defn][key] = complexity
          end
        end
      end
    end
  end
end
