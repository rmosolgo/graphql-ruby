module GraphQL
  class Query
    module SerialExecution
      def self.field_resolution
        FieldResolution
      end

      def self.fragment_spread_resolution
        FragmentSpreadResolution
      end

      def self.inline_fragment_resolution
        InlineFragmentResolution
      end

      def self.operation_resolution
        OperationResolution
      end

      def self.selection_resolution
        SelectionResolution
      end
    end
  end
end

require 'graphql/query/serial_execution/field_resolution'
require 'graphql/query/serial_execution/fragment_spread_resolution'
require 'graphql/query/serial_execution/inline_fragment_resolution'
require 'graphql/query/serial_execution/operation_resolution'
require 'graphql/query/serial_execution/selection_resolution'
