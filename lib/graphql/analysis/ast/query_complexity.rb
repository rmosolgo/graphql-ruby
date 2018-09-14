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
          @skip_stack = [false]
          @in_fragment_def = false
          @selection_sets = [Set.new]
        end

        def on_enter_field(node, parent, visitor)
          # We don't want to visit fragment definitions,
          # we'll visit them when we hit the spreads instead
          return if @in_fragment_def

          @visited_fields.last.add(node.alias || node.name)
          @visited_fields.push(Set.new)

          should_skip = @skip_stack.last || skip?(node)
          @skip_stack << should_skip
          return if should_skip

          @complexities_on_type.push(TypeComplexity.new)
        end

        def on_leave_field(node, parent, visitor)
          # We don't want to visit fragment definitions,
          # we'll visit them when we hit the spreads instead
          return if @in_fragment_def

          skipping = @skip_stack.pop
          return if skipping

          type_complexities = @complexities_on_type.pop
          child_complexity = type_complexities.max_possible_complexity
          own_complexity = get_complexity(visitor.field_definition, child_complexity)

          parent_type = visitor.parent_type_definition
          possible_types = if parent_type.kind.abstract?
            query.possible_types(parent_type)
          else
            [parent_type]
          end

          possible_types.each do |type|
            @complexities_on_type.last.merge(type, own_complexity)
          end
        end

        def on_enter_fragment_spread(node, parent, visitor)
          fragment_def = query.fragments[node.name]

          object_type = if fragment_def.type
            query.schema.types.fetch(fragment_def.type.name, nil)
          else
            visitor.last
          end

          visitor.object_types << object_type

          fragment_def.selections.each do |selection|
            visitor.visit_node(selection, fragment_def)
          end
        end

        def on_leave_fragment_spread(_, _, visitor)
          visitor.object_types.pop
        end

        def on_enter_fragment_definition(*)
          @in_fragment_def = true
        end

        def on_leave_fragment_definition(*)
          @in_fragment_def = false
        end

        def result
          @complexities_on_type.last.max_possible_complexity
        end

        private

        def skip?(ast_node)
          dir = ast_node.directives
          dir.any? && !GraphQL::Execution::DirectiveChecks.include?(dir, query)
        end

        # Get a complexity value for a field,
        # by getting the number or calling its proc
        def get_complexity(field_defn, child_complexity)
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
end
