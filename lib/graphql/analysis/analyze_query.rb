# frozen_string_literal: true
module GraphQL
  module Analysis
    module_function

    def use(schema_class)
      schema = schema_class.is_a?(Class) ? schema_class : schema_class.target
      schema.analysis_engine = self
    end

    # @return [void]
    def analyze_multiplex(multiplex, analyzers)
      multiplex.trace("analyze_multiplex", { multiplex: multiplex }) do
        reducer_states = analyzers.map { |r| ReducerState.new(r, multiplex) }
        query_results = multiplex.queries.map do |query|
          if query.valid?
            analyze_query(query, query.analyzers, multiplex_states: reducer_states)
          else
            []
          end
        end

        multiplex_results = reducer_states.map(&:finalize_reducer)
        multiplex_errors = analysis_errors(multiplex_results)

        multiplex.queries.each_with_index do |query, idx|
          query.analysis_errors = multiplex_errors + analysis_errors(query_results[idx])
        end
      end
      nil
    end

    # Visit `query`'s internal representation, calling `analyzers` along the way.
    #
    # - First, query analyzers are filtered down by calling `.analyze?(query)`, if they respond to that method
    # - Then, query analyzers are initialized by calling `.initial_value(query)`, if they respond to that method.
    # - Then, they receive `.call(memo, visit_type, irep_node)`, where visit type is `:enter` or `:leave`.
    # - Last, they receive `.final_value(memo)`, if they respond to that method.
    #
    # It returns an array of final `memo` values in the order that `analyzers` were passed in.
    #
    # @param query [GraphQL::Query]
    # @param analyzers [Array<#call>] Objects that respond to `#call(memo, visit_type, irep_node)`
    # @return [Array<Any>] Results from those analyzers
    def analyze_query(query, analyzers, multiplex_states: [])
      GraphQL::Deprecation.warn "Legacy analysis will be removed in GraphQL-Ruby 2.0, please upgrade to AST Analysis: https://graphql-ruby.org/queries/ast_analysis.html (schema: #{query.schema})"

      query.trace("analyze_query", { query: query }) do
        analyzers_to_run = analyzers.select do |analyzer|
          if analyzer.respond_to?(:analyze?)
            analyzer.analyze?(query)
          else
            true
          end
        end

        reducer_states = analyzers_to_run.map { |r| ReducerState.new(r, query) } + multiplex_states

        irep = query.internal_representation

        irep.operation_definitions.each do |name, op_node|
          reduce_node(op_node, reducer_states)
        end

        reducer_states.map(&:finalize_reducer)
      end
    end

    private

    module_function

    # Enter the node, visit its children, then leave the node.
    def reduce_node(irep_node, reducer_states)
      visit_analyzers(:enter, irep_node, reducer_states)

      irep_node.typed_children.each do |type_defn, children|
        children.each do |name, child_irep_node|
          reduce_node(child_irep_node, reducer_states)
        end
      end

      visit_analyzers(:leave, irep_node, reducer_states)
    end

    def visit_analyzers(visit_type, irep_node, reducer_states)
      reducer_states.each do |reducer_state|
        next_memo = reducer_state.call(visit_type, irep_node)

        reducer_state.memo = next_memo
      end
    end

    def analysis_errors(results)
      results.flatten.select { |r| r.is_a?(GraphQL::AnalysisError) }
    end
  end
end
