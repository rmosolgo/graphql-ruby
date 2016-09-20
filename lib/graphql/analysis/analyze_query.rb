module GraphQL
  module Analysis
    module_function
    # Visit `query`'s internal representation, calling `analyzers` along the way.
    #
    # - First, query analyzers are initialized by calling `.initial_value(query)`, if they respond to that method.
    # - Then, they receive `.call(memo, visit_type, irep_node)`, where visit type is `:enter` or `:leave`.
    # - Last, they receive `.final_value(memo)`, if they respond to that method.
    #
    # It returns an array of final `memo` values in the order that `analyzers` were passed in.
    #
    # @param query [GraphQL::Query]
    # @param analyzers [Array<#call>] Objects that respond to `#call(memo, visit_type, irep_node)`
    # @return [Array<Any>] Results from those analyzers
    def analyze_query(query, analyzers)
      reducer_states = analyzers.map { |r| ReducerState.new(r, query) }

      irep = query.internal_representation

      irep.each do |name, op_node|
        reduce_node(op_node, reducer_states)
      end

      reducer_states.map { |r| r.finalize_reducer }
    end

    private

    module_function

    # Enter the node, visit its children, then leave the node.
    def reduce_node(irep_node, reducer_states)
      visit_analyzers(:enter, irep_node, reducer_states)

      irep_node.children.each do |name, child_irep_node|
        reduce_node(child_irep_node, reducer_states)
      end

      visit_analyzers(:leave, irep_node, reducer_states)
    end

    def visit_analyzers(visit_type, irep_node, reducer_states)
      reducer_states.each do |reducer_state|
        next_memo = reducer_state.call(visit_type, irep_node)

        reducer_state.memo = next_memo
      end
    end
  end
end
