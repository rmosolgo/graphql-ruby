module GraphQL
  module Execution
    # GraphQL object `{value, current_type}` can be cast to `potential_type` when:
    # - `current_type == potential_type`
    # - `current_type` is a union and it resolves `value` to `potential_type`
    # - `potential_type` is a union and `current_type` is a member
    # - `current_type` is an interface and it resolves `value` to `potential_type`
    # - `potential_type` is an interface and `current_type` implements that interface
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
      def self.compatible?(value, current_type, potential_type, query_ctx)
        if current_type == potential_type
          true
        elsif current_type.kind.union?
          current_type.resolve_type(value, query_ctx) == potential_type
        elsif potential_type.kind.union?
          potential_type.include?(current_type)
        elsif current_type.kind.interface?
          current_type.resolve_type(value, query_ctx) == potential_type
        elsif potential_type.kind.interface?
          current_type.interfaces.include?(potential_type)
        else
          false
        end
      end
    end
  end
end
