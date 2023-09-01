# frozen_string_literal: true
module GraphQL
  class Schema
    # A subset of types and fields from the schema,
    # and may include other runtime settings.
    class Subset
      # @param name [Symbol]
      # @param schema [Class<GraphQL::Schema>]
      # @param context [Hash]
      def initialize(name:, schema:, context:)
        context[:schema_subset] ||= name
        full_context = schema.context_class.new(query: nil, object: nil, schema: schema, values: context)
        @warden = schema.warden_class.new(schema: schema, context: full_context)
        full_context.warden = @warden
      end

      # @return [GraphQL::Schema::Warden] This warden may be reused again and again for queries
      attr_reader :warden
    end
  end
end
