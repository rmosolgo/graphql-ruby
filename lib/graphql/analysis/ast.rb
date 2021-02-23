# frozen_string_literal: true
require "graphql/analysis/ast/visitor"
require "graphql/analysis/ast/analyzer"
require "graphql/analysis/ast/field_usage"
require "graphql/analysis/ast/query_complexity"
require "graphql/analysis/ast/max_query_complexity"
require "graphql/analysis/ast/query_depth"
require "graphql/analysis/ast/max_query_depth"

module GraphQL
  module Analysis
    module AST
      module_function

      def use(schema_class)
        if schema_class.analysis_engine == self
          definition_line = caller(2, 1).first
          GraphQL::Deprecation.warn("GraphQL::Analysis::AST is now the default; remove `use GraphQL::Analysis::AST` from the schema definition (#{definition_line})")
        else
          schema_class.analysis_engine = self
        end
      end

      # Analyze a multiplex, and all queries within.
      # Multiplex analyzers are ran for all queries, keeping state.
      # Query analyzers are ran per query, without carrying state between queries.
      #
      # @param multiplex [GraphQL::Execution::Multiplex]
      # @param analyzers [Array<GraphQL::Analysis::AST::Analyzer>]
      # @return [Array<Any>] Results from multiplex analyzers
      def analyze_multiplex(multiplex, analyzers)
        multiplex_analyzers = analyzers.map { |analyzer| analyzer.new(multiplex) }

        multiplex.trace("analyze_multiplex", { multiplex: multiplex }) do
          query_results = multiplex.queries.map do |query|
            if query.valid?
              analyze_query(
                query,
                query.analyzers,
                multiplex_analyzers: multiplex_analyzers
              )
            else
              []
            end
          end

          multiplex_results = multiplex_analyzers.map(&:result)
          multiplex_errors = analysis_errors(multiplex_results)

          multiplex.queries.each_with_index do |query, idx|
            query.analysis_errors = multiplex_errors + analysis_errors(query_results[idx])
          end
          multiplex_results
        end
      end

      # @param query [GraphQL::Query]
      # @param analyzers [Array<GraphQL::Analysis::AST::Analyzer>]
      # @return [Array<Any>] Results from those analyzers
      def analyze_query(query, analyzers, multiplex_analyzers: [])
        query.trace("analyze_query", { query: query }) do
          query_analyzers = analyzers
            .map { |analyzer| analyzer.new(query) }
            .select { |analyzer| analyzer.analyze? }

          analyzers_to_run = query_analyzers + multiplex_analyzers
          if analyzers_to_run.any?
            visitor = GraphQL::Analysis::AST::Visitor.new(
              query: query,
              analyzers: analyzers_to_run
            )

            visitor.visit

            if visitor.rescued_errors.any?
              visitor.rescued_errors
            else
              query_analyzers.map(&:result)
            end
          else
            []
          end
        end
      end

      def analysis_errors(results)
        results.flatten.select { |r| r.is_a?(GraphQL::AnalysisError) }
      end
    end
  end
end
