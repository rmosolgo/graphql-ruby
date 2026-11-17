# frozen_string_literal: true
#--
# typed: strict
module GraphQL
  module StaticValidation
    # The validation context gets passed to each validator.
    #
    # It exposes a [GraphQL::Language::Visitor](rdoc-ref:GraphQL::Language::Visitor) where validators may add hooks. ([Language::Visitor#visit](rdoc-ref:Language::Visitor#visit) is called in [Validator#validate](rdoc-ref:Validator#validate))
    #
    # It provides access to the schema & fragments which validators may read from.
    #
    # It holds a list of errors which each validator may add to.
    class ValidationContext
      extend Forwardable

      #: GraphQL::Query
      attr_reader :query

      #: Array[GraphQL::StaticValidation::Error]
      attr_reader :errors

      #: GraphQL::StaticValidation::BaseVisitor
      attr_reader :visitor

      #: Array[^(GraphQL::Language::Nodes::OperationDefinition | GraphQL::Language::Nodes::FragmentDefinition, Array[GraphQL::Language::Nodes::FragmentSpread], GraphQL::Language::Nodes::FragmentDefinition) -> void]
      attr_reader :on_dependency_resolve_handlers

      #: Integer | Float
      attr_reader :max_errors

      #: GraphQL::Schema::Visibility::Profile | GraphQL::Schema::Warden::VisibilityProfile
      attr_reader :types

      #: singleton(GraphQL::Schema)
      attr_reader :schema


      def_delegators :@query, :document, :fragments, :operations

      #: (GraphQL::Query query, singleton(GraphQL::StaticValidation::BaseVisitor) visitor_class, Integer? max_errors) -> void
      def initialize(query, visitor_class, max_errors)
        @query = query #: GraphQL::Query
        @types = query.types #: GraphQL::Schema::Visibility::Profile | GraphQL::Schema::Warden::VisibilityProfile
        @schema = query.schema #: singleton(GraphQL::Schema)
        @input_values = query.input_values #: GraphQL::Execution::InputValues
        @errors = [] #: Array[GraphQL::StaticValidation::Error]
        @max_errors = max_errors || Float::INFINITY #: Integer | Float
        @on_dependency_resolve_handlers = [] #: Array[^(GraphQL::Language::Nodes::OperationDefinition | GraphQL::Language::Nodes::FragmentDefinition, Array[GraphQL::Language::Nodes::FragmentSpread], GraphQL::Language::Nodes::FragmentDefinition) -> void]
        @visitor = visitor_class.new(document, self) #: GraphQL::StaticValidation::BaseVisitor
      end

      # TODO stop using def_delegators because of Array allocations
      def_delegators :@visitor,
        :path, :type_definition, :field_definition, :argument_definition,
        :parent_type_definition, :directive_definition, :dependencies

      #: () { (GraphQL::Language::Nodes::OperationDefinition | GraphQL::Language::Nodes::FragmentDefinition, Array[GraphQL::Language::Nodes::FragmentSpread], GraphQL::Language::Nodes::FragmentDefinition) -> void } -> void
      def on_dependency_resolve(&handler)
        @on_dependency_resolve_handlers << handler
      end

      INVALID_RESULT = GraphQL::Query::InputValidationResult.new(valid: false, problems: EmptyObjects::EMPTY_ARRAY).freeze #: GraphQL::Query::InputValidationResult
      private_constant :INVALID_RESULT

      #: (untyped ast_value, GraphQL::Schema::Member::type_definition | GraphQL::Schema::NonNull | GraphQL::Schema::List type) -> GraphQL::Query::InputValidationResult
      def validate_literal(ast_value, type)
        @input_values.value_from_ast(ast_value, type, validate: true)
        GraphQL::Query::InputValidationResult::VALID
      rescue Execution::InputValues::InvalidLiteralError => err
        if err.validation_result
          err.validation_result
        elsif err.explanation
          Query::InputValidationResult.from_problem(err.explanation)
        else
          INVALID_RESULT
        end
      rescue CoercionError => coercion_err
        Query::InputValidationResult.from_problem(coercion_err.message, message: coercion_err.message, extensions: coercion_err.extensions)
      end

      #: () -> bool
      def too_many_errors?
        @errors.length >= @max_errors
      end

      #: () -> Hash[String, singleton(GraphQL::Schema::Directive)]
      def schema_directives
        @schema_directives ||= schema.directives #: Hash[String, singleton(GraphQL::Schema::Directive)]?
      end

      #: (String name, Array[String] options) -> String?
      def did_you_mean_suggestion(name, options)
        if did_you_mean = schema.did_you_mean
          suggestions = did_you_mean.const_get(:SpellChecker).new(dictionary: options).correct(name)
          case suggestions.size
          when 0
            ""
          when 1
            " (Did you mean `#{suggestions.first}`?)"
          else
            last_sugg = suggestions.pop
            " (Did you mean #{suggestions.map {|s| "`#{s}`"}.join(", ")} or `#{last_sugg}`?)"
          end
        end
      end
    end
  end
end
