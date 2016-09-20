module GraphQL
  module Analysis
    module_function

    attr_reader :errors

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
      @errors = []

      analyzers_and_values = analyzers.map { |r| initialize_reducer(r, query) }

      irep = query.internal_representation

      irep.each do |name, op_node|
        reduce_node(op_node, analyzers_and_values)
      end

      if !@errors.blank?
        @errors.flatten
      else
        analyzers_and_values.map { |(r, value)| finalize_reducer(r, value) }
      end
    end

    private

    module_function

    # Enter the node, visit its children, then leave the node.
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

        begin
          next_memo = reducer.call(memo, visit_type, irep_node)
        rescue GraphQL::AnalysisError => e
          @errors << e
        end

        if next_memo.is_a?(Hash) && next_memo[:errors].present?
          @errors << next_memo[:errors]
          next_memo[:errors] = []
        end

        reducer_and_value[1] = next_memo
      end
    end

    # If the reducer has an `initial_value` method, call it and store
    # the result as `memo`. Otherwise, use `nil` as memo.
    # @return [Array<(#call, Any)>] reducer-memo pairs
    def initialize_reducer(reducer, query)
      if reducer.respond_to?(:initial_value)
        [reducer, reducer.initial_value(query)]
      else
        [reducer, nil]
      end
    end

    # If the reducer accepts `final_value`, send it the last memo value.
    # Otherwise, use the last value from the traversal.
    # @return [Any] final memo value
    def finalize_reducer(reducer, reduced_value)
      if @errors.present?
        @errors
      elsif reducer.respond_to?(:final_value)
        reducer.final_value(reduced_value)
      else
        reduced_value
      end
    end
  end
end
