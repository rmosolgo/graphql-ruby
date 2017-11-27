# frozen_string_literal: true
module GraphQL
  module Language
    module Nodes
      # {AbstractNode} is the base class for all nodes in a GraphQL AST.
      #
      # It provides some APIs for working with ASTs:
      # - `children` returns all AST nodes attached to this one. Used for tree traversal.
      # - `scalars` returns all scalar (Ruby) values attached to this one. Used for comparing nodes.
      # - `to_query_string` turns an AST node into a GraphQL string
      class AbstractNode
        attr_accessor :line, :col, :filename

        # Initialize a node by extracting its position,
        # then calling the class's `initialize_node` method.
        # @param options [Hash] Initial attributes for this node
        def initialize(options={})
          if options.key?(:position_source)
            position_source = options.delete(:position_source)
            @line, @col = position_source.line_and_column
          end

          @filename = options.delete(:filename)

          initialize_node(options)
        end

        # This is called with node-specific options
        def initialize_node(options={})
          raise NotImplementedError
        end

        # Value equality
        # @return [Boolean] True if `self` is equivalent to `other`
        def eql?(other)
          return true if equal?(other)
          other.is_a?(self.class) &&
            other.scalars.eql?(self.scalars) &&
            other.children.eql?(self.children)
        end

        # @return [Array<GraphQL::Language::Nodes::AbstractNode>] all nodes in the tree below this one
        def children
          self.class.child_attributes
            .map { |attr_name| public_send(attr_name) }
            .flatten
        end

        # @return [Array<Integer, Float, String, Boolean, Array>] Scalar values attached to this node
        def scalars
          self.class.scalar_attributes
            .map { |attr_name| public_send(attr_name) }
        end

        class << self
          # A node subclass inherits `scalar_attributes`
          # and `child_attributes` from its parent
          def inherited(subclass)
            subclass.scalar_attributes(*@scalar_attributes)
            subclass.child_attributes(*@child_attributes)
          end

          # define `attr_names` as places where scalars may be attached to this node
          def scalar_attributes(*attr_names)
            @scalar_attributes ||= []
            @scalar_attributes += attr_names
          end

          # define `attr_names` as places where child nodes may be attached to this node
          def child_attributes(*attr_names)
            @child_attributes ||= []
            @child_attributes += attr_names
          end
        end

        def position
          [line, col]
        end

        def to_query_string
          Generation.generate(self)
        end
      end

      # Base class for non-null type names and list type names
      class WrapperType < AbstractNode
        attr_accessor :of_type
        scalar_attributes :of_type

        def initialize_node(of_type: nil)
          @of_type = of_type
        end

        def children
          [].freeze
        end
      end

      # Base class for nodes whose only value is a name (no child nodes or other scalars)
      class NameOnlyNode < AbstractNode
        attr_accessor :name
        scalar_attributes :name

        def initialize_node(name: nil)
          @name = name
        end

        def children
          [].freeze
        end
      end

      # A key-value pair for a field's inputs
      class Argument < AbstractNode
        attr_accessor :name, :value
        scalar_attributes :name, :value

        # @!attribute name
        #   @return [String] the key for this argument

        # @!attribute value
        #   @return [String, Float, Integer, Boolean, Array, InputObject] The value passed for this key

        def initialize_node(name: nil, value: nil)
          @name = name
          @value = value
        end

        def children
          [value].flatten.select { |v| v.is_a?(AbstractNode) }
        end
      end

      class Directive < AbstractNode
        attr_accessor :name, :arguments
        scalar_attributes :name
        child_attributes :arguments

        def initialize_node(name: nil, arguments: [])
          @name = name
          @arguments = arguments
        end
      end

      class DirectiveDefinition < AbstractNode
        attr_accessor :name, :arguments, :locations, :description
        scalar_attributes :name
        child_attributes :arguments, :locations

        def initialize_node(name: nil, arguments: [], locations: [], description: nil)
          @name = name
          @arguments = arguments
          @locations = locations
          @description = description
        end
      end

      # This is the AST root for normal queries
      #
      # @example Deriving a document by parsing a string
      #   document = GraphQL.parse(query_string)
      #
      # @example Creating a string from a document
      #   document.to_query_string
      #   # { ... }
      #
      class Document < AbstractNode
        attr_accessor :definitions
        child_attributes :definitions

        # @!attribute definitions
        #   @return [Array<OperationDefinition, FragmentDefinition>] top-level GraphQL units: operations or fragments
        def initialize_node(definitions: [])
          @definitions = definitions
        end

        def slice_definition(name)
          GraphQL::Language::DefinitionSlice.slice(self, name)
        end
      end

      # An enum value. The string is available as {#name}.
      class Enum < NameOnlyNode; end

      # A null value literal.
      class NullValue < NameOnlyNode; end

      # A single selection in a GraphQL query.
      class Field < AbstractNode
        attr_accessor :name, :alias, :arguments, :directives, :selections
        scalar_attributes :name, :alias
        child_attributes :arguments, :directives, :selections

        # @!attribute selections
        #   @return [Array<Nodes::Field>] Selections on this object (or empty array if this is a scalar field)

        def initialize_node(name: nil, arguments: [], directives: [], selections: [], **kwargs)
          @name = name
          # oops, alias is a keyword:
          @alias = kwargs.fetch(:alias, nil)
          @arguments = arguments
          @directives = directives
          @selections = selections
        end
      end

      # A reusable fragment, defined at document-level.
      class FragmentDefinition < AbstractNode
        attr_accessor :name, :type, :directives, :selections
        scalar_attributes :name, :type
        child_attributes :directives, :selections

        # @!attribute name
        #   @return [String] the identifier for this fragment, which may be applied with `...#{name}`

        # @!attribute type
        #   @return [String] the type condition for this fragment (name of type which it may apply to)
        def initialize_node(name: nil, type: nil, directives: [], selections: [])
          @name = name
          @type = type
          @directives = directives
          @selections = selections
        end
      end

      # Application of a named fragment in a selection
      class FragmentSpread < AbstractNode
        attr_accessor :name, :directives
        scalar_attributes :name
        child_attributes :directives

        # @!attribute name
        #   @return [String] The identifier of the fragment to apply, corresponds with {FragmentDefinition#name}

        def initialize_node(name: nil, directives: [])
          @name = name
          @directives = directives
        end
      end

      # An unnamed fragment, defined directly in the query with `... {  }`
      class InlineFragment < AbstractNode
        attr_accessor :type, :directives, :selections
        scalar_attributes :type
        child_attributes :directives, :selections

        # @!attribute type
        #   @return [String, nil] Name of the type this fragment applies to, or `nil` if this fragment applies to any type

        def initialize_node(type: nil, directives: [], selections: [])
          @type = type
          @directives = directives
          @selections = selections
        end
      end

      # A collection of key-value inputs which may be a field argument
      class InputObject < AbstractNode
        attr_accessor :arguments
        child_attributes :arguments

        # @!attribute arguments
        #   @return [Array<Nodes::Argument>] A list of key-value pairs inside this input object

        def initialize_node(arguments: [])
          @arguments = arguments
        end

        # @return [Hash<String, Any>] Recursively turn this input object into a Ruby Hash
        def to_h(options={})
          arguments.inject({}) do |memo, pair|
            v = pair.value
            memo[pair.name] = serialize_value_for_hash v
            memo
          end
        end

        private

        def serialize_value_for_hash(value)
          if value.is_a? InputObject
            value.to_h
          elsif value.is_a? Array
            value.map do |v|
              serialize_value_for_hash v
            end
          elsif value.is_a? NullValue
            nil
          else
            value
          end
        end
      end


      # A list type definition, denoted with `[...]` (used for variable type definitions)
      class ListType < WrapperType; end

      # A non-null type definition, denoted with `...!` (used for variable type definitions)
      class NonNullType < WrapperType; end

      # A query, mutation or subscription.
      # May be anonymous or named.
      # May be explicitly typed (eg `mutation { ... }`) or implicitly a query (eg `{ ... }`).
      class OperationDefinition < AbstractNode
        attr_accessor :operation_type, :name, :variables, :directives, :selections
        scalar_attributes :operation_type, :name
        child_attributes :variables, :directives, :selections

        # @!attribute variables
        #   @return [Array<VariableDefinition>] Variable definitions for this operation

        # @!attribute selections
        #   @return [Array<Field>] Root-level fields on this operation

        # @!attribute operation_type
        #   @return [String, nil] The root type for this operation, or `nil` for implicit `"query"`

        # @!attribute name
        #   @return [String, nil] The name for this operation, or `nil` if unnamed

        def initialize_node(operation_type: nil, name: nil, variables: [], directives: [], selections: [])
          @operation_type = operation_type
          @name = name
          @variables = variables
          @directives = directives
          @selections = selections
        end
      end

      # A type name, used for variable definitions
      class TypeName < NameOnlyNode; end

      # An operation-level query variable
      class VariableDefinition < AbstractNode
        attr_accessor :name, :type, :default_value
        scalar_attributes :name, :type, :default_value

        # @!attribute default_value
        #   @return [String, Integer, Float, Boolean, Array, NullValue] A Ruby value to use if no other value is provided

        # @!attribute type
        #   @return [TypeName, NonNullType, ListType] The expected type of this value

        # @!attribute name
        #   @return [String] The identifier for this variable, _without_ `$`

        def initialize_node(name: nil, type: nil, default_value: nil)
          @name = name
          @type = type
          @default_value = default_value
        end
      end

      # Usage of a variable in a query. Name does _not_ include `$`.
      class VariableIdentifier < NameOnlyNode; end

      class SchemaDefinition < AbstractNode
        attr_accessor :query, :mutation, :subscription
        scalar_attributes :query, :mutation, :subscription

        def initialize_node(query: nil, mutation: nil, subscription: nil)
          @query = query
          @mutation = mutation
          @subscription = subscription
        end
      end

      class ScalarTypeDefinition < AbstractNode
        attr_accessor :name, :directives, :description
        scalar_attributes :name
        child_attributes :directives

        def initialize_node(name:, directives: [], description: nil)
          @name = name
          @directives = directives
          @description = description
        end
      end

      class ObjectTypeDefinition < AbstractNode
        attr_accessor :name, :interfaces, :fields, :directives, :description
        scalar_attributes :name
        child_attributes :interfaces, :fields, :directives

        def initialize_node(name:, interfaces:, fields:, directives: [], description: nil)
          @name = name
          @interfaces = interfaces || []
          @directives = directives
          @fields = fields
          @description = description
        end
      end

      class InputValueDefinition < AbstractNode
        attr_accessor :name, :type, :default_value, :directives,:description
        scalar_attributes :name, :type, :default_value
        child_attributes :directives

        def initialize_node(name:, type:, default_value: nil, directives: [], description: nil)
          @name = name
          @type = type
          @default_value = default_value
          @directives = directives
          @description = description
        end
      end

      class FieldDefinition < AbstractNode
        attr_accessor :name, :arguments, :type, :directives, :description
        scalar_attributes :name, :type
        child_attributes :arguments, :directives

        def initialize_node(name:, arguments:, type:, directives: [], description: nil)
          @name = name
          @arguments = arguments
          @type = type
          @directives = directives
          @description = description
        end
      end

      class InterfaceTypeDefinition < AbstractNode
        attr_accessor :name, :fields, :directives, :description
        scalar_attributes :name
        child_attributes :fields, :directives

        def initialize_node(name:, fields:, directives: [], description: nil)
          @name = name
          @fields = fields
          @directives = directives
          @description = description
        end
      end

      class UnionTypeDefinition < AbstractNode
        attr_accessor :name, :types, :directives, :description
        scalar_attributes :name
        child_attributes :types, :directives

        def initialize_node(name:, types:, directives: [], description: nil)
          @name = name
          @types = types
          @directives = directives
          @description = description
        end
      end

      class EnumTypeDefinition < AbstractNode
        attr_accessor :name, :values, :directives, :description
        scalar_attributes :name
        child_attributes :values, :directives

        def initialize_node(name:, values:, directives: [], description: nil)
          @name = name
          @values = values
          @directives = directives
          @description = description
        end
      end

      class EnumValueDefinition < AbstractNode
        attr_accessor :name, :directives, :description
        scalar_attributes :name
        child_attributes :directives

        def initialize_node(name:, directives: [], description: nil)
          @name = name
          @directives = directives
          @description = description
        end
      end

      class InputObjectTypeDefinition < AbstractNode
        attr_accessor :name, :fields, :directives, :description
        scalar_attributes :name
        child_attributes :fields

        def initialize_node(name:, fields:, directives: [], description: nil)
          @name = name
          @fields = fields
          @directives = directives
          @description = description
        end
      end
    end
  end
end
