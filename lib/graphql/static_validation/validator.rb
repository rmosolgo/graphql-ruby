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
      ### Ruby 1.9.3 unofficial support
      # def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
      def initialize(options = {})
        schema = options[:schema]
        rules = options.fetch(:rules, GraphQL::StaticValidation::ALL_RULES)

        @schema = schema
        @rules = rules
      end

      # Validate `query` against the schema. Returns an array of message hashes.
      # @param query [GraphQL::Query]
      # @return [Array<Hash>]
      def validate(query)
        context = GraphQL::StaticValidation::ValidationContext.new(query)
        rewrite = GraphQL::InternalRepresentation::Rewrite.new

        # Put this first so its enters and exits are always called
        rewrite.validate(context)
        @rules.each do |rules|
          rules.new.validate(context)
        end

        context.visitor.visit

        {
          errors: context.errors.map(&:to_h),
          # If there were errors, the irep is garbage
          irep: context.errors.none? ? rewrite.operations : nil,
        }
      end
    end
  end
end
