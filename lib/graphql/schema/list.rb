# frozen_string_literal: true

module GraphQL
  class Schema
    # Represents a list type in the schema.
    # Wraps a {Schema::Member} as a list type.
    # @see {Schema::Member::TypeSystemHelpers#to_list_type}
    class List < GraphQL::Schema::Wrapper
      extend Schema::Member::ValidatesInput

      def to_graphql
        @of_type.graphql_definition.to_list_type
      end

      # @return [GraphQL::TypeKinds::LIST]
      def kind
        GraphQL::TypeKinds::LIST
      end

      # @return [true]
      def list?
        true
      end

      def to_type_signature
        "[#{@of_type.to_type_signature}]"
      end


      def validate_input(value, ctx)

        result = GraphQL::Query::InputValidationResult.new

        if !value.nil?
          ensure_array(value).each_with_index do |item, index|
            if !item.nil?
              item_result = of_type.validate_input(item, ctx)
              if !item_result.valid?
                result.merge_result!(index, item_result)
              end
            end
          end
        end

        result
      end

      private

      def ensure_array(value)
        value.is_a?(Array) ? value : [value]
      end
    end
  end
end
