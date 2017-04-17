# frozen_string_literal: true
module GraphQL
  module Subscriptions
    class Event
      attr_reader :name, :arguments, :context
      def initialize(name:, arguments:, context:)
        @name = name
        @arguments = arguments
        @context = context
      end
    end
  end
end
