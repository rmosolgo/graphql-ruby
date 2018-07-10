# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # Initialized with a {GraphQL::Schema}, then it can validate {GraphQL::Language::Nodes::Documents}s based on that schema.
    #
    # By default, it's used by {GraphQL::Query}
    #
    # @example Validate a query
    #   validator = GraphQL::StaticValidation::Validator.new(schema: MySchema)
    #   query = GraphQL::Query.new(MySchema, query_string)
    #   errors = validator.validate(query)[:errors]
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
      def validate(query, validate: true)
        query.trace("validate", { validate: validate, query: query }) do

          rules_to_use = validate ? @rules : []
          visitor_class = BaseVisitor.including_rules(rules_to_use)

          context = GraphQL::StaticValidation::ValidationContext.new(query, visitor_class)

          # Attach legacy-style rules
          rules_to_use.each do |rule_class_or_module|
            if rule_class_or_module.method_defined?(:validate)
              rule_class_or_module.new.validate(context)
            end
          end

          context.visitor.visit
          # Post-validation: allow validators to register handlers on rewritten query nodes
          rewrite_result = context.visitor.rewrite_document
          GraphQL::InternalRepresentation::Visit.visit_each_node(rewrite_result.operation_definitions, context.each_irep_node_handlers)

          {
            errors: context.errors,
            # If there were errors, the irep is garbage
            irep: context.errors.any? ? nil : rewrite_result,
          }
        end
      end
    end
  end
end
