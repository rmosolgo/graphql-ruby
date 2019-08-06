# frozen_string_literal: true
module GraphQL
  module Define
    # Wrap the object in NonNullType in response to `!`
    # @example required Int type
    #   !GraphQL::INT_TYPE
    #
    module NonNullWithBang
      # Make the type non-null
      # @return [GraphQL::NonNullType] a non-null type which wraps the original type
      def !
        to_non_null_type
      end
    end
  end
end
