# frozen_string_literal: true
module GraphQL
  module Subscriptions
    class Event
      attr_reader :name, :arguments, :context, :key
      def initialize(name:, arguments:, context:)
        @name = name
        @arguments = arguments
        @context = context
        @key = self.class.serialize(name, arguments)
      end

      def self.serialize(name, arguments)
        "#{name}(#{JSON.dump(arguments.to_h)})"
      end
    end
  end
end
