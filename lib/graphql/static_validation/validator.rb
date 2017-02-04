# frozen_string_literal: true
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
      # @param rules [Array<#validate(context)>] a list of rules to use when validating
      def initialize(schema:, rules: GraphQL::StaticValidation::ALL_RULES)
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
        # Post-validation: allow validators to register handlers on rewritten query nodes
        rewrite_result = rewrite.operations
        GraphQL::InternalRepresentation::Visit.visit_each_node(rewrite_result, context.each_irep_node_handlers)

        {
          errors: context.errors,
          # If there were errors, the irep is garbage
          irep: context.errors.any? ? nil : rewrite_result,
        }
      end
    end
  end
end
