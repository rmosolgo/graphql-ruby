# frozen_string_literal: true

require "graphql/analysis"

module GraphQL
  module Analysis
    # A complexity calculator that intends to replicate Shopify's complexity calculation for cost estimation.
    # The cost estimation is based on a static analysis of the query.
    # It does not require running the query nor does it require the actual data.
    # This is because it is a cost estimate, not the actual cost.
    class ShopifyComplexity < GraphQL::Analysis::QueryComplexity
      attr_reader :field_costs

      def initialize(query)
        super
        @field_costs = []
      end

      def result
        # Return both the total complexity and the field breakdown
        total_complexity = super
        {
          total: total_complexity,
          fields: @field_costs
        }
      end

      # This class overrides the default complexity calculation for a field.
      # Ref: https://shopify.dev/docs/api/usage/limits#cost-calculation
      # Ref: https://graphql-ruby.org/queries/complexity_and_depth.html#how-complexity-scoring-works
      # Shopify says: For simplicity, that ^ summary describes all linear tally strategies.
      #   We do incorporate logarithmic scaling into connection fields to cost them more favorably for a client.
      class ShopifyScopedTypeComplexity < ScopedTypeComplexity
        attr_accessor :analyzer

        # Known fields that Shopify assigns 0 cost to
        # Based on observation: These are "primitive value objects" - information wrappers
        # without an identity or lifecycle in Shopify's domain model.
        # Source: https://community.shopify.dev/t/how-to-calculate-graphql-cost-estimates/24364/6
        ZERO_COST_FIELDS = %w[
          address
          billingAddress
          currencyFormats
          measurement
          unitCost
          pageInfo
        ].freeze

        def own_complexity(child_complexity = 0)
          return child_complexity unless @field_definition

          field_type = @field_definition.type.unwrap

          # Calculate the cost for this field
          field_cost = calculate_field_cost(field_type, child_complexity)

          # Record this field's cost for debugging
          record_field_cost(field_cost, child_complexity)

          field_cost
        end

        private

        def calculate_field_cost(field_type, child_complexity)
          # Shopify: Some fields are "primitive value objects" and have zero cost
          return 0 if ZERO_COST_FIELDS.include?(@field_definition.graphql_name)

          if @field_definition.owner == @query.schema.mutation
            # Shopify: mutations have a flat cost of 10, regardless of return fields
            10
          elsif @field_definition.connection?
            # Shopify-style: only multiply the items (nodes/edges) subtree by an effective, capped page size
            # and add a small, separate metadata cost (eg, pageInfo subfields), avoiding nested double-multiplication.
            # Shopify formula: cost = mult × items_complexity + 2
            # The mult is applied only to items (nodes/edges), not pageInfo (which costs 0)
            # The +2 is the metadata cost
            mult = effective_connection_size(@nodes, @query)
            (mult * child_complexity) + 2
          else
            case field_type.kind
            when GraphQL::TypeKinds::OBJECT, GraphQL::TypeKinds::INTERFACE, GraphQL::TypeKinds::UNION
              1 + child_complexity
            else # SCALAR, ENUM, INPUT_OBJECT, LIST, NON_NULL
              child_complexity
            end
          end
        end

        private

        # Effective connection size using Shopify's actual formula
        # Formula: cost = 2 + children_cost * (2 * Math.log([2, sizing].max)).floor if sizing > 0
        # Source: https://community.shopify.dev/t/how-to-calculate-graphql-cost-estimates/24364/6
        # Returns the multiplier for the connection based on the requested page size
        def effective_connection_size(nodes, query)
          sizing = 1  # default if no first/last provided
          
          nodes.each do |node|
            args = query.arguments_for(node, @field_definition)
            current = args[:first] || args[:last]
            sizing = [sizing, current].max if current
          end

          # Cap at 250 (Shopify's max page size)
          sizing = [sizing, 250].min

          # Apply Shopify's actual formula: multiplier = (2 * ln(max(2, sizing))).floor
          return 0 if sizing == 0
          (2 * Math.log([2, sizing].max)).floor
        end

        def record_field_cost(total_cost, child_complexity)
          return unless @analyzer

          # Shopify's definedCost is a fixed cost they add (their "thumb on the scale").
          # We always use 0 since we're not replicating their manual adjustments.
          defined_cost = 0

          # Build the path array for this field
          path = @response_path.dup

          # Record in the analyzer's field costs
          @analyzer.field_costs << {
            path: path,
            definedCost: defined_cost,
            requestedTotalCost: total_cost,
            requestedChildrenCost: child_complexity
          }
        end
      end

      # Override on_enter_field from QueryComplexity to use our shopify scope class.
      # This is a bit of a reimplementation of the base method, but it's necessary
      # to inject our shopify complexity calculation logic.
      def on_enter_field(node, parent, visitor)
        # We don't want to visit fragment definitions,
        # we'll visit them when we hit the spreads instead
        return if visitor.visiting_fragment_definition?
        return if visitor.skipping?
        return if @skip_introspection_fields && visitor.field_definition.introspection?
        parent_type = visitor.parent_type_definition
        field_key = node.alias || node.name

        # Find or create a complexity scope stack for this query.
        scopes_stack = @complexities_on_type_by_query[visitor.query] ||= begin
          root_scope = ShopifyScopedTypeComplexity.new(nil, nil, visitor.query, visitor.response_path)
          root_scope.analyzer = self
          [root_scope]
        end

        # Find or create the complexity costing node for this field.
        scope = scopes_stack.last[parent_type][field_key] ||= begin
          new_scope = ShopifyScopedTypeComplexity.new(parent_type, visitor.field_definition, visitor.query, visitor.response_path)
          new_scope.analyzer = self
          new_scope
        end
        scope.nodes.push(node)
        scopes_stack.push(scope)
      end
    end
  end
end
