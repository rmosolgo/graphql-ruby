# frozen_string_literal: true
module GraphQL
  module Analysis
    # Calculate the complexity of a query, using {Field#complexity} values.
    module AST
      class QueryComplexity < Analyzer
        # State for the query complexity calculation:
        # - `complexities_on_type` holds complexity scores for each type
        def initialize(query)
          super
          @complexities_on_type_by_query = {}
        end

        # Overide this method to use the complexity result
        def result
          max_possible_complexity
        end

        class ScopedTypeComplexity
          # A single proc for {#scoped_children} hashes. Use this to avoid repeated allocations,
          # since the lexical binding isn't important.
          HASH_CHILDREN = ->(h, k) { h[k] = {} }

          attr_reader :field_definition, :response_path, :query

          # @param parent_type [Class] The owner of `field_definition`
          # @param field_definition [GraphQL::Field, GraphQL::Schema::Field] Used for getting the `.complexity` configuration
          # @param query [GraphQL::Query] Used for `query.possible_types`
          # @param response_path [Array<String>] The path to the response key for the field
          def initialize(parent_type, field_definition, query, response_path)
            @parent_type = parent_type
            @field_definition = field_definition
            @query = query
            @response_path = response_path
            @scoped_children = nil
            @nodes = []
          end

          # @return [Array<GraphQL::Language::Nodes::Field>]
          attr_reader :nodes

          # Returns true if this field has no selections, ie, it's a scalar.
          # We need a quick way to check whether we should continue traversing.
          def terminal?
            @scoped_children.nil?
          end

          # This value is only calculated when asked for to avoid needless hash allocations.
          # Also, if it's never asked for, we determine that this scope complexity
          # is a scalar field ({#terminal?}).
          # @return [Hash<Hash<Class => ScopedTypeComplexity>]
          def scoped_children
            @scoped_children ||= Hash.new(&HASH_CHILDREN)
          end

          def own_complexity(child_complexity)
            @field_definition.calculate_complexity(query: @query, nodes: @nodes, child_complexity: child_complexity)
          end
        end

        def on_enter_field(node, parent, visitor)
          # We don't want to visit fragment definitions,
          # we'll visit them when we hit the spreads instead
          return if visitor.visiting_fragment_definition?
          return if visitor.skipping?
          parent_type = visitor.parent_type_definition
          field_key = node.alias || node.name
          # Find the complexity calculation for this field --
          # if we're re-entering a selection, we'll already have one.
          # Otherwise, make a new one and store it.
          #
          # `node` and `visitor.field_definition` may appear from a cache,
          # but I think that's ok. If the arguments _didn't_ match,
          # then the query would have been rejected as invalid.
          complexities_on_type = @complexities_on_type_by_query[visitor.query] ||= [ScopedTypeComplexity.new(nil, nil, query, visitor.response_path)]

          complexity = complexities_on_type.last.scoped_children[parent_type][field_key] ||= ScopedTypeComplexity.new(parent_type, visitor.field_definition, visitor.query, visitor.response_path)
          complexity.nodes.push(node)
          # Push it on the stack.
          complexities_on_type.push(complexity)
        end

        def on_leave_field(node, parent, visitor)
          # We don't want to visit fragment definitions,
          # we'll visit them when we hit the spreads instead
          return if visitor.visiting_fragment_definition?
          return if visitor.skipping?
          complexities_on_type = @complexities_on_type_by_query[visitor.query]
          complexities_on_type.pop
        end

        private

        # @return [Integer]
        def max_possible_complexity
          @complexities_on_type_by_query.reduce(0) do |total, (query, complexities_on_type)|
            root_complexity = complexities_on_type.last
            # Use this entry point to calculate the total complexity
            total_complexity_for_query = merged_max_complexity_for_scopes(query, [root_complexity.scoped_children])
            total + total_complexity_for_query
          end
        end

        # @param query [GraphQL::Query] Used for `query.possible_types`
        # @param scoped_children_hashes [Array<Hash>] Array of scoped children hashes
        # @return [Integer]
        def merged_max_complexity_for_scopes(query, scoped_children_hashes)
          # Figure out what scopes are possible here.
          # Use a hash, but ignore the values; it's just a fast way to work with the keys.
          all_scopes = {}
          scoped_children_hashes.each do |h|
            all_scopes.merge!(h)
          end

          # If an abstract scope is present, but _all_ of its concrete types
          # are also in the list, remove it from the list of scopes to check,
          # because every possible type is covered by a concrete type.
          # (That is, there are no remainder types to check.)
          prev_keys = all_scopes.keys
          prev_keys.each do |scope|
            next unless scope.kind.abstract?

            missing_concrete_types = query.possible_types(scope).select { |t| !all_scopes.key?(t) }
            # This concrete type is possible _only_ as a member of the abstract type.
            # So, attribute to it the complexity which belongs to the abstract type.
            missing_concrete_types.each do |concrete_scope|
              all_scopes[concrete_scope] = all_scopes[scope]
            end
            all_scopes.delete(scope)
          end

          # This will hold `{ type => int }` pairs, one for each possible branch
          complexity_by_scope = {}

          # For each scope,
          # find the lexical selections that might apply to it,
          # and gather them together into an array.
          # Then, treat the set of selection hashes
          # as a set and calculate the complexity for them as a unit
          all_scopes.each do |scope, _|
            # These will be the selections on `scope`
            children_for_scope = []
            scoped_children_hashes.each do |sc_h|
              sc_h.each do |inner_scope, children_hash|
                if applies_to?(query, scope, inner_scope)
                  children_for_scope << children_hash
                end
              end
            end

            # Calculate the complexity for `scope`, merging all
            # possible lexical branches.
            complexity_value = merged_max_complexity(query, children_for_scope)
            complexity_by_scope[scope] = complexity_value
          end

          # Return the max complexity among all scopes
          complexity_by_scope.each_value.max
        end

        def applies_to?(query, left_scope, right_scope)
          if left_scope == right_scope
            # This can happen when several branches are being analyzed together
            true
          else
            # Check if these two scopes have _any_ types in common.
            possible_right_types = query.possible_types(right_scope)
            possible_left_types = query.possible_types(left_scope)
            !(possible_right_types & possible_left_types).empty?
          end
        end

        # A hook which is called whenever a field's max complexity is calculated.
        # Override this method to capture individual field complexity details.
        #
        # @param scoped_type_complexity [ScopedTypeComplexity]
        # @param max_complexity [Numeric] Field's maximum complexity including child complexity
        # @param child_complexity [Numeric, nil] Field's child complexity
        def field_complexity(scoped_type_complexity, max_complexity:, child_complexity: nil)
        end

        # @param children_for_scope [Array<Hash>] An array of `scoped_children[scope]` hashes
        # (`{field_key => complexity}`)
        # @return [Integer] Complexity value for all these selections in the current scope
        def merged_max_complexity(query, children_for_scope)
          all_keys = []
          children_for_scope.each do |c|
            all_keys.concat(c.keys)
          end
          all_keys.uniq!
          complexity_for_keys = {}

          all_keys.each do |child_key|
            scoped_children_for_key = nil
            complexity_for_key = nil
            children_for_scope.each do |children_hash|
              next unless children_hash.key?(child_key)

              complexity_for_key = children_hash[child_key]
              if complexity_for_key.terminal?
                # Assume that all terminals would return the same complexity
                # Since it's a terminal, its child complexity is zero.
                complexity = complexity_for_key.own_complexity(0)
                complexity_for_keys[child_key] = complexity

                field_complexity(complexity_for_key, max_complexity: complexity, child_complexity: nil)
              else
                scoped_children_for_key ||= []
                scoped_children_for_key << complexity_for_key.scoped_children
              end
            end

            next unless scoped_children_for_key

            child_complexity = merged_max_complexity_for_scopes(query, scoped_children_for_key)
            # This is the _last_ one we visited; assume it's representative.
            max_complexity = complexity_for_key.own_complexity(child_complexity)

            field_complexity(complexity_for_key, max_complexity: max_complexity, child_complexity: child_complexity)

            complexity_for_keys[child_key] = max_complexity
          end

          # Calculate the child complexity by summing the complexity of all selections
          complexity_for_keys.each_value.inject(0, &:+)
        end
      end
    end
  end
end
