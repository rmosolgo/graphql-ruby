# frozen_string_literal: true
module GraphQL
  class Schema
    # A shape is a subset of types and fields from the schema,
    # and may include other runtime settings.
    class Shape
      # @param name [Symbol]
      # @param schema [Class<GraphQL::Schema>]
      # @param context [Hash]
      def initialize(name:, schema:, context:)
        context[:shape_name] ||= name
        @context = schema.context_class.new(query: nil, object: nil, schema: schema, values: context)
        @warden = schema.warden_class.new(schema: schema, context: @context)
      end

      # @return [GraphQL::Schema::Warden] This warden may be reused again and again for queries
      attr_reader :warden
    end
  end
end
