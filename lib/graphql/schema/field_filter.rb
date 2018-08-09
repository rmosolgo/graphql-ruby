# frozen_string_literal: true
module GraphQL
  class Schema

    # TODO rename? since it's more than just filter
    class FieldFilter
      # @return [GraphQL::Schema::Field]
      attr_reader :field

      # @return [Object]
      attr_reader :options

      def initialize(field:, options:)
        @field = field
        @options = options
      end

      def before_resolve(object:, arguments:, context:)
        yield(object, arguments)
      end

      def after_resolve(object:, arguments:, context:, value:)
        value
      end
    end
  end
end
