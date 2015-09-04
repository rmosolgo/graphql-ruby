require 'graphql/query/base_execution/selected_object_resolution'
require 'graphql/query/base_execution/value_resolution'

module GraphQL
  class Query
    class BaseExecution
      # @param ast_operation [GraphQL::Language::Nodes::OperationDefinition] The operation definition to run
      # @param root_type [GraphQL::ObjectType] either the query type or the mutation type
      # @param query_obj [GraphQL::Query] the query object for this execution
      # @return [Hash] a spec-compliant GraphQL result, as a hash
      def execute(ast_operation, root_type, query_obj)
        resolver = operation_resolution.new(ast_operation, root_type, query_obj, self)
        resolver.result
      end

      def field_resolution
        get_class :FieldResolution
      end

      def fragment_spread_resolution
        get_class :FragmentSpreadResolution
      end

      def inline_fragment_resolution
        get_class :InlineFragmentResolution
      end

      def operation_resolution
        get_class :OperationResolution
      end

      def selection_resolution
        get_class :SelectionResolution
      end

      # ParallelExecution overrides this to provide
      # real async behavior
      def async(&block)
        block.call
      end

      private

      def get_class(class_name)
        self.class.const_get(class_name)
      end
    end
  end
end
