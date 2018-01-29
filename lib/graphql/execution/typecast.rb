# frozen_string_literal: true
module GraphQL
  module Execution
    # @api private
    module Typecast
      # @return [Boolean]
      def self.subtype?(parent_type, child_type)
        # NOTE: this avoids BaseType#== because it's kind of slow.
        # TODO: make that faster?
        if child_type.is_a?(GraphQL::NonNullType) && !parent_type.is_a?(GraphQL::NonNullType)
          child_type = child_type.of_type
        end

        case parent_type
        when GraphQL::ObjectType
          # This is a common case so let's move it up
          parent_type.name == child_type.name
        when GraphQL::InterfaceType
          # A type is a subtype of an interface
          # if it implements that interface
          case child_type
          when GraphQL::ObjectType
            child_type.interfaces.include?(parent_type)
          when GraphQL::InterfaceType
            parent_type.name == child_type.name
          else
            false
          end
        when GraphQL::UnionType
          case child_type
          when GraphQL::ObjectType
            # A type is a subtype of that union
            # if the union includes that type
            parent_type.possible_types.include?(child_type)
          when GraphQL::UnionType
            parent_type.name == child_type.name
          else
            false
          end
        when GraphQL::ListType
          # A list type is a subtype of another list type
          # if its inner type is a subtype of the other inner type
          case child_type
          when GraphQL::ListType
            subtype?(parent_type.of_type, child_type.of_type)
          else
            false
          end
        when GraphQL::NonNullType
          case child_type
          when GraphQL::NonNullType
            subtype?(parent_type.of_type, child_type.of_type)
          else
            false
          end
        else
          parent_type.name == child_type.name
        end
      end
    end
  end
end
