module GraphQL
  module StaticValidation
    # The validation context gets passed to each validator.
    #
    # It exposes a {GraphQL::Language::Visitor} where validators may add hooks. ({Visitor#visit} is called in {Validator#validate})
    #
    # It provides access to the schema & fragments which validators may read from.
    #
    # It holds a list of errors which each validator may add to.
    #
    # It also provides limited access to the {TypeStack} instance,
    # which tracks state as you climb in and out of different fields.
    class ValidationContext
      attr_reader :query, :schema, :document, :errors, :visitor, :fragments, :operations
      def initialize(query)
        @query = query
        @schema = query.schema
        @document = query.document
        @fragments = {}
        @operations = {}

        document.definitions.each do |definition|
          case definition
          when GraphQL::Language::Nodes::FragmentDefinition
            @fragments[definition.name] = definition
          when GraphQL::Language::Nodes::OperationDefinition
            @operations[definition.name] = definition
          end
        end

        @errors = []
        @visitor = GraphQL::Language::Visitor.new
        @type_stack = GraphQL::StaticValidation::TypeStack.new(schema, visitor)
      end

      def object_types
        @type_stack.object_types
      end

      # @return [GraphQL::Field, nil] The most-recently-entered GraphQL::Field, if currently inside one
      def field_definition
        @type_stack.field_definitions.last
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

      # Don't try to validate dynamic fields
      # since they aren't defined by the type system
      def skip_field?(field_name)
        GraphQL::Schema::DYNAMIC_FIELDS.include?(field_name)
      end
    end
  end
end
