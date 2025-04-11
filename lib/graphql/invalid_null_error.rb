# frozen_string_literal: true
module GraphQL
  # Raised automatically when a field's resolve function returns `nil`
  # for a non-null field.
  class InvalidNullError < GraphQL::Error
    # @return [GraphQL::BaseType] The owner of {#field}
    attr_reader :parent_type

    # @return [GraphQL::Field] The field which failed to return a value
    attr_reader :field

    # @return [GraphQL::Language::Nodes::Field] the field where the error occurred
    attr_reader :ast_node

    # @return [Boolean] indicates an array result caused the error
    attr_reader :is_from_array

    def initialize(parent_type, field, ast_node, is_from_array: false)
      @parent_type = parent_type
      @field = field
      @ast_node = ast_node
      @is_from_array = is_from_array

      # For List elements, identify the non-null error is for an
      # element and the required element type so it's not ambiguous
      # whether it was caused by a null instead of the list or a
      # null element.
      if @is_from_array
        super("Cannot return null for non-nullable element of type '#{@field.type.of_type.of_type.to_type_signature}' for #{@parent_type.graphql_name}.#{@field.graphql_name}")
      else
        super("Cannot return null for non-nullable field #{@parent_type.graphql_name}.#{@field.graphql_name}")
      end
    end

    class << self
      attr_accessor :parent_class

      def subclass_for(parent_class)
        subclass = Class.new(self)
        subclass.parent_class = parent_class
        subclass
      end

      def inspect
        if (name.nil? || parent_class&.name.nil?) && parent_class.respond_to?(:mutation) && (mutation = parent_class.mutation)
          "#{mutation.inspect}::#{parent_class.graphql_name}::InvalidNullError"
        else
          super
        end
      end
    end
  end
end
