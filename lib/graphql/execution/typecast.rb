module GraphQL
  module Execution
    # GraphQL object `{value, type}` can be cast to `other_type` when:
    # - `type == other_type`
    # - `type` is a union and it resolves `value` to `other_type`
    # - `other_type` is a union and `type` is a member
    # - `type` is an interface and it resolves `value` to `other_type`
    # - `other_type` is an interface and `type` implements that interface
    module Typecast
      # While `value` is exposed by GraphQL as an instance of `current_type`,
      # should it _also_ be treated as an instance of `potential_type`?
      #
      # This is used for checking whether fragments apply to an object.
      #
      # @return [Boolean] Can `value` be evaluated as a `potential_type`?
      def self.compatible?(value, current_type, potential_type, query_ctx)
        if potential_type == current_type
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
