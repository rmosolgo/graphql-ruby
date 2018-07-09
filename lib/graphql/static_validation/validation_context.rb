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

      attr_reader :query, :schema,
        :document, :errors, :visitor,
        :warden, :dependencies, :each_irep_node_handlers

      def_delegators :@query, :schema, :document, :fragments, :operations, :warden

      def initialize(query)
        @query = query
        @literal_validator = LiteralValidator.new(context: query.context)
        @errors = []
        @visitor = GraphQL::Language::Visitor.new(document)
        @type_stack = GraphQL::StaticValidation::TypeStack.new(schema, visitor)
        definition_dependencies = DefinitionDependencies.mount(self)
        @on_dependency_resolve_handlers = []
        @each_irep_node_handlers = []
        visitor[GraphQL::Language::Nodes::Document].leave << ->(_n, _p) {
          @dependencies = definition_dependencies.dependency_map { |defn, spreads, frag|
            @on_dependency_resolve_handlers.each { |h| h.call(defn, spreads, frag) }
          }
        }
      end

      def on_dependency_resolve(&handler)
        @on_dependency_resolve_handlers << handler
      end

      def object_types
        @type_stack.object_types
      end

      def each_irep_node(&handler)
        @each_irep_node_handlers << handler
      end

      # @return [GraphQL::BaseType] The current object type
      def type_definition
        object_types.last
      end

      # @return [GraphQL::BaseType] The type which the current type came from
      def parent_type_definition
        object_types[-2]
      end

      # @return [GraphQL::Field, nil] The most-recently-entered GraphQL::Field, if currently inside one
      def field_definition
        @type_stack.field_definitions.last
      end

      # @return [Array<String>] Field names to get to the current field
      def path
        @type_stack.path.dup
      end

      # @return [GraphQL::Directive, nil] The most-recently-entered GraphQL::Directive, if currently inside one
      def directive_definition
        @type_stack.directive_definitions.last
      end

      # @return [GraphQL::Argument, nil] The most-recently-entered GraphQL::Argument, if currently inside one
      def argument_definition
        # Don't get the _last_ one because that's the current one.
        # Get the second-to-last one, which is the parent of the current one.
        @type_stack.argument_definitions[-2]
      end

      def valid_literal?(ast_value, type)
        @literal_validator.validate(ast_value, type)
      end
    end
  end
end
