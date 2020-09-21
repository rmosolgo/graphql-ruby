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
        module DefinitionNode
          # This AST node's {#line} returns the first line, which may be the description.
          # @return [Integer] The first line of the definition (not the description)
          attr_reader :definition_line

          def initialize(options = {})
            @definition_line = options.delete(:definition_line)
            super(options)
          end
        end

        attr_reader :line, :col, :filename

        # Initialize a node by extracting its position,
        # then calling the class's `initialize_node` method.
        # @param options [Hash] Initial attributes for this node
        def initialize(options = {})
          if options.key?(:position_source)
            position_source = options.delete(:position_source)
            @line = position_source.line
            @col = position_source.col
          end

          @filename = options.delete(:filename)

          initialize_node(**options)
        end

        # Value equality
        # @return [Boolean] True if `self` is equivalent to `other`
        def ==(other)
          return true if equal?(other)
          other.kind_of?(self.class) &&
            other.scalars == self.scalars &&
            other.children == self.children
        end

        NO_CHILDREN = [].freeze

        # @return [Array<GraphQL::Language::Nodes::AbstractNode>] all nodes in the tree below this one
        def children
          NO_CHILDREN
        end

        # @return [Array<Integer, Float, String, Boolean, Array>] Scalar values attached to this node
        def scalars
          NO_CHILDREN
        end

        # This might be unnecessary, but its easiest to add it here.
        def initialize_copy(other)
          @children = nil
          @scalars = nil
          @query_string = nil
        end

        def children_method_name
          self.class.children_method_name
        end

        def position
          [line, col]
        end

        def to_query_string(printer: GraphQL::Language::Printer.new)
          if printer.is_a?(GraphQL::Language::Printer)
            @query_string ||= printer.print(self)
          else
            printer.print(self)
          end
        end

        # This creates a copy of `self`, with `new_options` applied.
        # @param new_options [Hash]
        # @return [AbstractNode] a shallow copy of `self`
        def merge(new_options)
          dup.merge!(new_options)
        end

        # Copy `self`, but modify the copy so that `previous_child` is replaced by `new_child`
        def replace_child(previous_child, new_child)
          # Figure out which list `previous_child` may be found in
          method_name = previous_child.children_method_name
          # Get the value from this (original) node
          prev_children = public_send(method_name)
          if prev_children.is_a?(Array)
            # Copy that list, and replace `previous_child` with `new_child`
            # in the list.
            new_children = prev_children.dup
            prev_idx = new_children.index(previous_child)
            new_children[prev_idx] = new_child
          else
            # Use the new value for the given attribute
            new_children = new_child
          end
          # Copy this node, but with the new child value
          copy_of_self = merge(method_name => new_children)
          # Return the copy:
          copy_of_self
        end

        # TODO DRY with `replace_child`
        def delete_child(previous_child)
          # Figure out which list `previous_child` may be found in
          method_name = previous_child.children_method_name
          # Copy that list, and delete previous_child
          new_children = public_send(method_name).dup
          new_children.delete(previous_child)
          # Copy this node, but with the new list of children:
          copy_of_self = merge(method_name => new_children)
          # Return the copy:
          copy_of_self
        end

        protected

        def merge!(new_options)
          new_options.each do |key, value|
            instance_variable_set(:"@#{key}", value)
          end
          self
        end

        class << self
          # Add a default `#visit_method` and `#children_method_name` using the class name
          def inherited(child_class)
            super
            name_underscored = child_class.name
              .split("::").last
              .gsub(/([a-z])([A-Z])/,'\1_\2') # insert underscores
              .downcase # remove caps

            child_class.module_eval <<-RUBY
              def visit_method
                :on_#{name_underscored}
              end

              class << self
                attr_accessor :children_method_name
              end
              self.children_method_name = :#{name_underscored}s
            RUBY
          end

          private

          # Name accessors which return lists of nodes,
          # along with the kind of node they return, if possible.
          # - Add a reader for these children
          # - Add a persistent update method to add a child
          # - Generate a `#children` method
          def children_methods(children_of_type)
            if defined?(@children_methods)
              raise "Can't re-call .children_methods for #{self} (already have: #{@children_methods})"
            else
              @children_methods = children_of_type
            end

            if children_of_type == false
              @children_methods = {}
              # skip
            else

              children_of_type.each do |method_name, node_type|
                module_eval <<-RUBY, __FILE__, __LINE__
                  # A reader for these children
                  attr_reader :#{method_name}
                RUBY

                if node_type
                  # Only generate a method if we know what kind of node to make
                  module_eval <<-RUBY, __FILE__, __LINE__
                    # Singular method: create a node with these options
                    # and return a new `self` which includes that node in this list.
                    def merge_#{method_name.to_s.sub(/s$/, "")}(node_opts)
                      merge(#{method_name}: #{method_name} + [#{node_type.name}.new(node_opts)])
                    end
                  RUBY
                end
              end

              if children_of_type.size == 1
                module_eval <<-RUBY, __FILE__, __LINE__
                  alias :children #{children_of_type.keys.first}
                RUBY
              else
                module_eval <<-RUBY, __FILE__, __LINE__
                  def children
                    @children ||= (#{children_of_type.keys.map { |k| "@#{k}" }.join(" + ")}).freeze
                  end
                RUBY
              end
            end

            if defined?(@scalar_methods)
              if !method_defined?(:initialize_node)
                generate_initialize_node
              else
                # This method was defined manually
              end
            else
              raise "Can't generate_initialize_node because scalar_methods wasn't called; call it before children_methods"
            end
          end

          # These methods return a plain Ruby value, not another node
          # - Add reader methods
          # - Add a `#scalars` method
          def scalar_methods(*method_names)
            if defined?(@scalar_methods)
              raise "Can't re-call .scalar_methods for #{self} (already have: #{@scalar_methods})"
            else
              @scalar_methods = method_names
            end

            if method_names == [false]
              @scalar_methods = []
              # skip it
            else
              module_eval <<-RUBY, __FILE__, __LINE__
                # add readers for each scalar
                attr_reader #{method_names.map { |m| ":#{m}"}.join(", ")}

                def scalars
                  @scalars ||= [#{method_names.map { |k| "@#{k}" }.join(", ")}].freeze
                end
              RUBY
            end
          end

          def generate_initialize_node
            scalar_method_names = @scalar_methods
            # TODO: These probably should be scalar methods, but `types` returns an array
            [:types, :description].each do |extra_method|
              if method_defined?(extra_method)
                scalar_method_names += [extra_method]
              end
            end

            all_method_names = scalar_method_names + @children_methods.keys
            if all_method_names.include?(:alias)
              # Rather than complicating this special case,
              # let it be overridden (in field)
              return
            else
              arguments = scalar_method_names.map { |m| "#{m}: nil"} +
                @children_methods.keys.map { |m| "#{m}: NO_CHILDREN" }

              assignments = scalar_method_names.map { |m| "@#{m} = #{m}"} +
                @children_methods.keys.map { |m| "@#{m} = #{m}.freeze" }

              module_eval <<-RUBY, __FILE__, __LINE__
                def initialize_node #{arguments.join(", ")}
                  #{assignments.join("\n")}
                end
              RUBY
            end
          end
        end
      end

      # Base class for non-null type names and list type names
      class WrapperType < AbstractNode
        scalar_methods :of_type
        children_methods(false)
      end

      # Base class for nodes whose only value is a name (no child nodes or other scalars)
      class NameOnlyNode < AbstractNode
        scalar_methods :name
        children_methods(false)
      end

      # A key-value pair for a field's inputs
      class Argument < AbstractNode
        scalar_methods :name, :value
        children_methods(false)

        # @!attribute name
        #   @return [String] the key for this argument

        # @!attribute value
        #   @return [String, Float, Integer, Boolean, Array, InputObject] The value passed for this key

        def children
          @children ||= Array(value).flatten.select { |v| v.is_a?(AbstractNode) }
        end
      end

      class Directive < AbstractNode
        scalar_methods :name
        children_methods(arguments: GraphQL::Language::Nodes::Argument)
      end

      class DirectiveLocation < NameOnlyNode
      end

      class DirectiveDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name
        children_methods(
          locations: Nodes::DirectiveLocation,
          arguments: Nodes::Argument,
        )
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
      # @example Creating a custom string from a document
      #  class VariableScrubber < GraphQL::Language::Printer
      #    def print_argument(arg)
      #      "#{arg.name}: <HIDDEN>"
      #    end
      #  end
      #
      #  document.to_query_string(printer: VariableSrubber.new)
      #
      class Document < AbstractNode
        scalar_methods false
        children_methods(definitions: nil)
        # @!attribute definitions
        #   @return [Array<OperationDefinition, FragmentDefinition>] top-level GraphQL units: operations or fragments

        def slice_definition(name)
          GraphQL::Language::DefinitionSlice.slice(self, name)
        end
      end

      # An enum value. The string is available as {#name}.
      class Enum < NameOnlyNode
      end

      # A null value literal.
      class NullValue < NameOnlyNode
      end

      # A single selection in a GraphQL query.
      class Field < AbstractNode
        NONE = [].freeze

        scalar_methods :name, :alias
        children_methods({
          arguments: GraphQL::Language::Nodes::Argument,
          selections: GraphQL::Language::Nodes::Field,
          directives: GraphQL::Language::Nodes::Directive,
        })

        # @!attribute selections
        #   @return [Array<Nodes::Field>] Selections on this object (or empty array if this is a scalar field)

        def initialize_node(attributes)
          @name = attributes[:name]
          @arguments = attributes[:arguments] || NONE
          @directives = attributes[:directives] || NONE
          @selections = attributes[:selections] || NONE
          # oops, alias is a keyword:
          @alias = attributes[:alias]
        end

        # Override this because default is `:fields`
        self.children_method_name = :selections
      end

      # A reusable fragment, defined at document-level.
      class FragmentDefinition < AbstractNode
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

        scalar_methods :name, :type
        children_methods({
          selections: GraphQL::Language::Nodes::Field,
          directives: GraphQL::Language::Nodes::Directive,
        })

        self.children_method_name = :definitions
      end

      # Application of a named fragment in a selection
      class FragmentSpread < AbstractNode
        scalar_methods :name
        children_methods(directives: GraphQL::Language::Nodes::Directive)

        self.children_method_name = :selections

        # @!attribute name
        #   @return [String] The identifier of the fragment to apply, corresponds with {FragmentDefinition#name}
      end

      # An unnamed fragment, defined directly in the query with `... {  }`
      class InlineFragment < AbstractNode
        scalar_methods :type
        children_methods({
          selections: GraphQL::Language::Nodes::Field,
          directives: GraphQL::Language::Nodes::Directive,
        })

        self.children_method_name = :selections

        # @!attribute type
        #   @return [String, nil] Name of the type this fragment applies to, or `nil` if this fragment applies to any type
      end

      # A collection of key-value inputs which may be a field argument
      class InputObject < AbstractNode
        scalar_methods(false)
        children_methods(arguments: GraphQL::Language::Nodes::Argument)

        # @!attribute arguments
        #   @return [Array<Nodes::Argument>] A list of key-value pairs inside this input object

        # @return [Hash<String, Any>] Recursively turn this input object into a Ruby Hash
        def to_h(options={})
          arguments.inject({}) do |memo, pair|
            v = pair.value
            memo[pair.name] = serialize_value_for_hash v
            memo
          end
        end

        self.children_method_name = :value

        private

        def serialize_value_for_hash(value)
          case value
          when InputObject
            value.to_h
          when Array
            value.map do |v|
              serialize_value_for_hash v
            end
          when Enum
            value.name
          when NullValue
            nil
          else
            value
          end
        end
      end


      # A list type definition, denoted with `[...]` (used for variable type definitions)
      class ListType < WrapperType
      end

      # A non-null type definition, denoted with `...!` (used for variable type definitions)
      class NonNullType < WrapperType
      end

      # An operation-level query variable
      class VariableDefinition < AbstractNode
        scalar_methods :name, :type, :default_value
        children_methods false
        # @!attribute default_value
        #   @return [String, Integer, Float, Boolean, Array, NullValue] A Ruby value to use if no other value is provided

        # @!attribute type
        #   @return [TypeName, NonNullType, ListType] The expected type of this value

        # @!attribute name
        #   @return [String] The identifier for this variable, _without_ `$`

        self.children_method_name = :variables
      end

      # A query, mutation or subscription.
      # May be anonymous or named.
      # May be explicitly typed (eg `mutation { ... }`) or implicitly a query (eg `{ ... }`).
      class OperationDefinition < AbstractNode
        scalar_methods :operation_type, :name
        children_methods({
          variables: GraphQL::Language::Nodes::VariableDefinition,
          selections: GraphQL::Language::Nodes::Field,
          directives: GraphQL::Language::Nodes::Directive,
        })

        # @!attribute variables
        #   @return [Array<VariableDefinition>] Variable $definitions for this operation

        # @!attribute selections
        #   @return [Array<Field>] Root-level fields on this operation

        # @!attribute operation_type
        #   @return [String, nil] The root type for this operation, or `nil` for implicit `"query"`

        # @!attribute name
        #   @return [String, nil] The name for this operation, or `nil` if unnamed

        self.children_method_name = :definitions
      end

      # A type name, used for variable definitions
      class TypeName < NameOnlyNode
      end

      # Usage of a variable in a query. Name does _not_ include `$`.
      class VariableIdentifier < NameOnlyNode
        self.children_method_name = :value
      end

      class SchemaDefinition < AbstractNode
        include DefinitionNode
        scalar_methods :query, :mutation, :subscription
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :definitions
      end

      class SchemaExtension < AbstractNode
        scalar_methods :query, :mutation, :subscription
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :definitions
      end

      class ScalarTypeDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :definitions
      end

      class ScalarTypeExtension < AbstractNode
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :definitions
      end

      class InputValueDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name, :type, :default_value
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :fields
      end

      class FieldDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name, :type
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          arguments: GraphQL::Language::Nodes::InputValueDefinition,
        })
        self.children_method_name = :fields

        # this is so that `children_method_name` of `InputValueDefinition` works properly
        # with `#replace_child`
        alias :fields :arguments
        def merge(new_options)
          if (f = new_options.delete(:fields))
            new_options[:arguments] = f
          end
          super
        end
      end

      class ObjectTypeDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name, :interfaces
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        })
        self.children_method_name = :definitions
      end

      class ObjectTypeExtension < AbstractNode
        scalar_methods :name, :interfaces
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        })
        self.children_method_name = :definitions
      end

      class InterfaceTypeDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        })
        self.children_method_name = :definitions
      end

      class InterfaceTypeExtension < AbstractNode
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        })
        self.children_method_name = :definitions
      end

      class UnionTypeDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description, :types
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :definitions
      end

      class UnionTypeExtension < AbstractNode
        attr_reader :types
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :definitions
      end

      class EnumValueDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
        })
        self.children_method_name = :values
      end

      class EnumTypeDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          values: GraphQL::Language::Nodes::EnumValueDefinition,
        })
        self.children_method_name = :definitions
      end

      class EnumTypeExtension < AbstractNode
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          values: GraphQL::Language::Nodes::EnumValueDefinition,
        })
        self.children_method_name = :definitions
      end

      class InputObjectTypeDefinition < AbstractNode
        include DefinitionNode
        attr_reader :description
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::InputValueDefinition,
        })
        self.children_method_name = :definitions
      end

      class InputObjectTypeExtension < AbstractNode
        scalar_methods :name
        children_methods({
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::InputValueDefinition,
        })
        self.children_method_name = :definitions
      end
    end
  end
end
