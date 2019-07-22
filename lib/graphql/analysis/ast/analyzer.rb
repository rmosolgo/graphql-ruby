# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      # Query analyzer for query ASTs. Query analyzers respond to visitor style methods
      # but are prefixed by `enter` and `leave`.
      #
      # @param query [GraphQL::Query] The queries to analyze
      # @param multiplex [Graphql::Execute::Multiplex]
      class Analyzer
        def initialize(query, multiplex: nil)
          @query = query
          @multiplex = multiplex
        end

        # Analyzer hook to decide at analysis time whether a query should
        # be analyzed or not.
        # @return [Boolean] If the query should be analyzed or not
        def analyze?
          true
        end

        # The result for this analyzer. Returning {GraphQL::AnalysisError} results
        # in a query error.
        # @return [Any] The analyzer result
        def result
          raise NotImplementedError
        end

        # Return true or false based on wether this Analyzer is being used as a
        # multiplex analyzer or a query analyzer
        # @return [Boolean] Is or is not a multiplex analyzer
        def multiplex?
          !multiplex.nil?
        end

        # Accessor to change what GraphQL::Query the @query variable points to. This
        # is used in a multiplex query to change the current query being visited as each
        # query is being analyzed.
        # @param [GraphQL::Query] The current query being visited
        def set_current_query(current_query)
          @query = current_query
        end

        # Don't use make_visit_method because it breaks `super`
        def self.build_visitor_hooks(member_name)
          class_eval(<<-EOS, __FILE__, __LINE__ + 1)
            def on_enter_#{member_name}(node, parent, visitor)
            end

            def on_leave_#{member_name}(node, parent, visitor)
            end
          EOS
        end

        build_visitor_hooks :argument
        build_visitor_hooks :directive
        build_visitor_hooks :document
        build_visitor_hooks :enum
        build_visitor_hooks :field
        build_visitor_hooks :fragment_spread
        build_visitor_hooks :inline_fragment
        build_visitor_hooks :input_object
        build_visitor_hooks :list_type
        build_visitor_hooks :non_null_type
        build_visitor_hooks :null_value
        build_visitor_hooks :operation_definition
        build_visitor_hooks :type_name
        build_visitor_hooks :variable_definition
        build_visitor_hooks :variable_identifier
        build_visitor_hooks :abstract_node

        protected

        attr_reader :query
        attr_reader :multiplex
      end
    end
  end
end
