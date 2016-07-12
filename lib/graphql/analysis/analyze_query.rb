module GraphQL
  module Analysis
    module_function
    # @param query [GraphQL::Query]
    # @param analyzers [Array<[#call]>]
    # @return [Array<Any>]
    def analyze_query(query, analyzers)
      analyzers_and_values = analyzers.map { |r| initialize_reducer(r, query) }

      irep = query.internal_representation

      irep.each do |name, op_node|
        reduce_node(op_node, analyzers_and_values)
      end

      analyzers_and_values.map { |(r, value)| finalize_reducer(r, value) }
    end

    private

    module_function

    def reduce_node(irep_node, analyzers_and_values)
      visit_analyzers(:enter, irep_node, analyzers_and_values)

      irep_node.children.each do |name, child_irep_node|
        reduce_node(child_irep_node, analyzers_and_values)
      end

      visit_analyzers(:leave, irep_node, analyzers_and_values)
    end

    def visit_analyzers(visit_type, irep_node, analyzers_and_values)
      analyzers_and_values.each do |reducer_and_value|
        reducer = reducer_and_value[0]
        memo = reducer_and_value[1]
        next_memo = reducer.call(memo, visit_type, irep_node)
        reducer_and_value[1] = next_memo
      end
    end

    def initialize_reducer(reducer, query)
      if reducer.respond_to?(:initial_value)
        [reducer, reducer.initial_value(query)]
      else
        [reducer, nil]
      end
    end

    def finalize_reducer(reducer, reduced_value)
      if reducer.respond_to?(:final_value)
        reducer.final_value(reduced_value)
      else
        reduced_value
      end
    end
  end
end
