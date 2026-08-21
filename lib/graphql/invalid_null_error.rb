# frozen_string_literal: true
module GraphQL
  # Raised automatically when a field's resolve function returns `nil`
  # for a non-null field.
  class InvalidNullError < GraphQL::RuntimeError
    # **Returns**
    #
    # - `GraphQL::BaseType` — The owner of [field](rdoc-ref:#field)
    #
    # :call-seq:
    #   parent_type -> GraphQL::BaseType
    attr_reader :parent_type

    # **Returns**
    #
    # - `GraphQL::Field` — The field which failed to return a value
    #
    # :call-seq:
    #   field -> GraphQL::Field
    attr_reader :field

    # **Returns**
    #
    # - `GraphQL::Language::Nodes::Field` — the field where the error occurred
    #
    # :call-seq:
    #   ast_node() -> GraphQL::Language::Nodes::Field
    def ast_node
      @ast_nodes.first
    end

    attr_reader :ast_nodes

    # **Returns**
    #
    # - `Boolean` — indicates an array result caused the error
    #
    # :call-seq:
    #   is_from_array -> bool
    attr_reader :is_from_array

    attr_accessor :path

    def initialize(parent_type, field, ast_node_or_nodes, is_from_array: false, path: nil)
      @parent_type = parent_type
      @field = field
      @ast_nodes = Array(ast_node_or_nodes)
      @is_from_array = is_from_array
      @path = path
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
