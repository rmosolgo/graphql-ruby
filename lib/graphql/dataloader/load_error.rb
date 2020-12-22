# frozen_string_literal: true
module GraphQL
  class Dataloader
    class LoadError < GraphQL::Error
      # @return [Array<Integer, String>] The runtime GraphQL path where the failed load was requested
      attr_accessor :graphql_path

      attr_writer :message

      def message
        @message || super
      end

      attr_writer :cause

      def cause
        @cause || super
      end
    end
  end
end
