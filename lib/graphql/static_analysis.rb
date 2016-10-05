require "graphql/static_analysis/analysis_error"
require "graphql/static_analysis/definition_dependencies"
require "graphql/static_analysis/definition_names"
require "graphql/static_analysis/type_check"
require "graphql/static_analysis/variable_usages"

require "graphql/static_analysis/rules/arguments_are_unique"
require "graphql/static_analysis/rules/definition_names_are_valid"
require "graphql/static_analysis/rules/fragments_are_valid"
require "graphql/static_analysis/rules/variable_usages_are_valid"


module GraphQL
  # TODO: is this the right name for this operation?
  #
  # Ride along with a {GraphQL::Language::Visitor}
  # to analyze a GraphQL AST. Check for usage errors in the query.
  #
  # @example Analyzing a GraphQL query string
  #   query_ast = GraphQL.parse(query_string)
  #   visitor = GraphQL::Language::Visitor.new(query_ast)
  #   analysis = GraphQL::StaticAnalysis.prepare(visitor)
  #   # Traverse the AST, which executes the analysis
  #   visitor.visit
  #   # Check for errors:
  #   puts analysis.errors
  #
  module StaticAnalysis
    # Initialize a new analysis, which will
    # be triggered by visiting the document
    # @return [GraphQL::StaticAnalysis::Analysis]
    def self.prepare(visitor, schema: nil)
      rules = DOCUMENT_RULES
      Analysis.new(visitor: visitor, rules: rules, schema: schema)
    end

    # These rules require a document _only_, not a schema.
    DOCUMENT_RULES = [
      Rules::ArgumentsAreUnique,
      Rules::FragmentsAreValid,
      Rules::DefinitionNamesAreValid,
      Rules::VariableUsagesAreValid,
    ]

    # This object exposes some data to the rules.
    # You have to run the visitor,
    # then you can ask for its errors,
    # which will contain errors for _all_ the rules.
    class Analysis
      attr_reader :visitor, :definition_names, :dependencies, :variable_usages, :schema

      # @return [Array<String>] Trace of current node during visit
      attr_reader :trace

      def initialize(visitor:, rules:, schema: nil)
        @visitor = visitor
        @schema = schema
        @trace = []
        @rule_instances = rules.map { |rule_class| rule_class.new(self) }

        GraphQL::Language::TraceVisitor.attach_enter(visitor, @trace)
        @definition_names = DefinitionNames.mount(visitor)
        variable_usages_visitor = VariableUsages.mount(visitor)
        definition_dependencies = DefinitionDependencies.mount(visitor)

        visitor[GraphQL::Language::Nodes::Document].leave << -> (node, prev_node) {
          @dependencies = definition_dependencies.dependency_map
          @variable_usages = variable_usages_visitor.usages(dependencies: dependencies)
        }

        # Mount this _after_ the above hook, so that type_check
        # will have access to dependencies and variables
        if schema
          type_check = TypeCheck.new(self)
          type_check.mount(visitor)
          @rule_instances << type_check
        end

        GraphQL::Language::TraceVisitor.attach_leave(visitor, @trace)
      end

      # You have to run the visitor before calling this.
      # @return [Array<AnalysisError>]
      def errors
        @errors ||= begin
          errs = []
          @rule_instances.each { |rule| errs.concat(rule.errors) }
          errs
        end
      end
    end
  end
end
