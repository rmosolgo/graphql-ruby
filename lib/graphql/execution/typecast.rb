# frozen_string_literal: true
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
      # @param current_type [GraphQL::BaseType] the type which GraphQL is using now
      # @param potential_type [GraphQL::BaseType] can this type be used from here?
      # @param query_ctx [GraphQL::Query::Context] the context for the current query
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

      def self.subtype?(parent_type, child_type)
        if parent_type == child_type
          # Equivalent types are subtypes
          true
        elsif child_type.is_a?(GraphQL::NonNullType)
          # A non-null type is a subtype of a nullable type
          # if its inner type is a subtype of that type
          if parent_type.is_a?(GraphQL::NonNullType)
            subtype?(parent_type.of_type, child_type.of_type)
          else
            subtype?(parent_type, child_type.of_type)
          end
        else
          case parent_type
          when GraphQL::InterfaceType
            # A type is a subtype of an interface
            # if it implements that interface
            case child_type
            when GraphQL::ObjectType
              child_type.interfaces.include?(parent_type)
            else
              false
            end
          when GraphQL::UnionType
            # A type is a subtype of that interface
            # if the union includes that interface
            parent_type.possible_types.include?(child_type)
          when GraphQL::ListType
            # A list type is a subtype of another list type
            # if its inner type is a subtype of the other inner type
            case child_type
            when GraphQL::ListType
              subtype?(parent_type.of_type, child_type.of_type)
            else
              false
            end
          else
            false
          end
        end
      end
    end
  end
end
