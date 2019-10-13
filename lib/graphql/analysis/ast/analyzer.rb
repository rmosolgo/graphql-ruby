# frozen_string_literal: true
module GraphQL
  module Analysis
    module AST
      # Query analyzer for query ASTs. Query analyzers respond to visitor style methods
      # but are prefixed by `enter` and `leave`.
      #
      # @param [GraphQL::Query] The query to analyze
      class Analyzer
        def initialize(query)
          @query = query
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
          raise GraphQL::RequiredImplementationMissingError
        end

        class << self
          private

          def build_visitor_hooks(member_name)
            class_eval(<<-EOS, __FILE__, __LINE__ + 1)
              def on_enter_#{member_name}(node, parent, visitor)
              end

              def on_leave_#{member_name}(node, parent, visitor)
              end
            EOS
          end
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
      end
    end
  end
end
