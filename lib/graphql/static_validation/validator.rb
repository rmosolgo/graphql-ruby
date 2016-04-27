module GraphQL
  module StaticValidation
    # Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Language::Nodes::Documents}s based on that schema.
    #
    # By default, it's used by {GraphQL::Query}
    #
    # @example Validate a query
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
    #   document = GraphQL.parse(query_string)
    #   errors = validator.validate(document)
    #
    class Validator
      # @param schema [GraphQL::Schema]
      # @param rule [Array<#validate(context)>] a list of rules to use when validating
      def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
        @schema = schema
        @rules = rules
      end

      # Validate `document` against the schema. Returns an array of message hashes.
      # @param document [GraphQL::Language::Nodes::Document]
      # @return [Array<Hash>]
      def validate(query)
        context = GraphQL::StaticValidation::ValidationContext.new(query)
        @rules.each do |rules|
          rules.new.validate(context)
        end
        context.visitor.visit(query.document)
        context.errors.map(&:to_h)
      end
    end
  end
end
