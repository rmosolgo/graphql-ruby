# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # The validation context gets passed to each validator.
    #
    # It exposes a {GraphQL::Language::Visitor} where validators may add hooks. ({Language::Visitor#visit} is called in {Validator#validate})
    #
    # It provides access to the schema & fragments which validators may read from.
    #
    # It holds a list of errors which each validator may add to.
    #
    # It also provides limited access to the {TypeStack} instance,
    # which tracks state as you climb in and out of different fields.
    class ValidationContext
      extend Forwardable

      attr_reader :query, :errors, :visitor,
        :on_dependency_resolve_handlers,
        :max_errors

      def_delegators :@query, :schema, :document, :fragments, :operations, :warden

      def initialize(query, visitor_class, max_errors)
        @query = query
        @literal_validator = LiteralValidator.new(context: query.context)
        @errors = []
        @max_errors = max_errors || Float::INFINITY
        @on_dependency_resolve_handlers = []
        @visitor = visitor_class.new(document, self)
      end

      def_delegators :@visitor,
        :path, :type_definition, :field_definition, :argument_definition,
        :parent_type_definition, :directive_definition, :object_types, :dependencies

      def on_dependency_resolve(&handler)
        @on_dependency_resolve_handlers << handler
      end

      def validate_literal(ast_value, type)
        @literal_validator.validate(ast_value, type)
      end

      def too_many_errors?
        @errors.length >= @max_errors
      end

      def schema_directives
        @schema_directives ||= schema.directives
      end
    end
  end
end
