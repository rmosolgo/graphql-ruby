module GraphQL
  module Analysis
    module_function
    # @param query [GraphQL::Query]
    # @param reducers [Array<[#call]>]
    # @return [Array<Any>]
    def reduce_query(query, reducers)
      reducers_and_values = reducers.map { |r| initialize_reducer(r, query) }

      irep = query.internal_representation

      irep.each do |name, op_node|
        reduce_node(op_node, reducers_and_values)
      end

      reducers_and_values.map { |(r, value)| finalize_reducer(r, value) }
    end

    private

    module_function

    def reduce_node(irep_node, reducers_and_values)
      reducers_and_values.each do |reducer_and_value|
        reducer = reducer_and_value[0]
        memo = reducer_and_value[1]
        next_memo = reducer.call(memo, :enter, irep_node)
        reducer_and_value[1] = next_memo
      end

      irep_node.children.each do |name, child_irep_node|
        reduce_node(child_irep_node, reducers_and_values)
      end

      reducers_and_values.each do |reducer_and_value|
        reducer = reducer_and_value[0]
        memo = reducer_and_value[1]
        next_memo = reducer.call(memo, :leave, irep_node)
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
