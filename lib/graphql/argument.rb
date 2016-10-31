module GraphQL
  # Used for defined arguments ({Field}, {InputObjectType})
  #
  # {#name} must be a String.
  #
  # @example defining an argument for a field
  #   GraphQL::Field.define do
  #     # ...
  #     argument :favoriteFood, types.String, "Favorite thing to eat", default_value: "pizza"
  #   end
  #
  # @example defining an argument for an {InputObjectType}
  #   GraphQL::InputObjectType.define do
  #     argument :newName, !types.String
  #   end
  #
  class Argument
    include GraphQL::Define::InstanceDefinable
    accepts_definitions :name, :type, :description, :default_value

    lazy_methods do
      attr_accessor :description, :default_value

      def name
        @name
      end

      def name=(new_name)
        @name = new_name
      end

      # @param new_input_type [GraphQL::BaseType, Proc] Assign a new input type for this argument (if it's a proc, it will be called after schema initialization)
      def type=(new_input_type)
        ensure_defined
        @clean_type = nil
        @dirty_type = new_input_type
      end

      # @return [GraphQL::BaseType] the input type for this argument
      def type
        @clean_type ||= begin
          ensure_defined
          GraphQL::BaseType.resolve_related_type(@dirty_type)
        end
      end
    end

    # @!attribute name
    #   @return [String] The name of this argument on its {GraphQL::Field} or {GraphQL::InputObjectType}
  end
end
