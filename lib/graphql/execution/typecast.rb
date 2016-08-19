module GraphQL
  module Execution
    # GraphQL object `{value, current_type}` can be cast to `potential_type` when:
    # - `current_type == potential_type`
    # - `current_type` is a union and it contains `potential_type`
    # - `potential_type` is a union and it contains `current_type`
    # - `current_type` is an interface and `potential_type` implements it
    # - `potential_type` is an interface and `current_type` implements it
    module Typecast
      # While `value` is exposed by GraphQL as an instance of `current_type`,
      # should it _also_ be treated as an instance of `potential_type`?
      #
      # This is used for checking whether fragments apply to an object.
      #
      # @param [Object] the value which GraphQL is currently exposing
      # @param [GraphQL::BaseType] the type which GraphQL is using for `value` now
      # @param [GraphQL::BaseType] can `value` be exposed using this type?
      # @param [GraphQL::Query::Context] the context for the current query
      # @return [Boolean] true if `value` be evaluated as a `potential_type`
      def self.compatible?(current_type, potential_type, query_ctx)
        if current_type == potential_type
          true
        elsif current_type.kind.union?
          current_type.possible_types.include?(potential_type)
        elsif potential_type.kind.union?
          potential_type.include?(current_type)
        elsif current_type.kind.interface? && potential_type.kind.object?
          potential_type.interfaces.include?(current_type)
        elsif potential_type.kind.interface? && current_type.kind.object?
          current_type.interfaces.include?(potential_type)
        else
          false
        end
      end
    end
  end
end
