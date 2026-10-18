# frozen_string_literal: true
# typed: true
module GraphQL
  module Language
    module Nodes
      NONE = GraphQL::EmptyObjects::EMPTY_ARRAY
      # [AbstractNode](rdoc-ref:GraphQL::Language::Nodes::AbstractNode) is the base class for all nodes in a GraphQL AST.
      #
      # It provides some APIs for working with ASTs:
      # - `children` returns all AST nodes attached to this one. Used for tree traversal.
      # - `scalars` returns all scalar (Ruby) values attached to this one. Used for comparing nodes.
      # - `to_query_string` turns an AST node into a GraphQL string
      class AbstractNode

        module DefinitionNode
          # This AST node's [line](rdoc-ref:GraphQL::Language::Nodes::AbstractNode#line) returns the first line, which may be the description.
          #
          # **Returns**
          #
          # - `Integer` — The first line of the definition (not the description)
          attr_reader :definition_line

          def initialize(definition_line: nil, **_rest)
            @definition_line = definition_line
            super(**_rest)
          end

          def marshal_dump
            super << @definition_line
          end

          def marshal_load(values)
            @definition_line = values.pop
            super
          end
        end

        attr_reader :filename

        def line
          @line ||= @source&.line_at(@pos)
        end

        def col
          @col ||= @source&.column_at(@pos)
        end

        def definition_line
          @definition_line ||= (@source && @definition_pos) ? @source.line_at(@definition_pos) : nil
        end

        # Value equality
        #
        # **Returns**
        #
        # - `Boolean` — True if `self` is equivalent to `other`
        #
        # :call-seq:
        #   ==(other) -> bool
        def ==(other)
          return true if equal?(other)
          other.kind_of?(self.class) &&
            other.scalars == self.scalars &&
            other.children == self.children
        end

        NO_CHILDREN = GraphQL::EmptyObjects::EMPTY_ARRAY

        # **Returns**
        #
        # - `Array<GraphQL::Language::Nodes::AbstractNode>` — all nodes in the tree below this one
        #
        # :call-seq:
        #   children() -> Array[GraphQL::Language::Nodes::AbstractNode]
        def children
          NO_CHILDREN
        end

        # **Returns**
        #
        # - `Array<Integer, Float, String, Boolean, Array>` — Scalar values attached to this node
        #
        # :call-seq:
        #   scalars() -> Array[Integer | Float | String | bool | Array]
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

        # Built-in node classes override this with a literal Symbol.
        #
        # **Returns**
        #
        # - `Symbol` — the method that GraphQL::Language::Visitor calls for this node
        def visit_method
          self.class.visit_method
        end

        def position
          [line, col]
        end

        def to_query_string(printer: GraphQL::Language::Printer.new)
          if printer.is_a?(GraphQL::Language::Printer)
            if frozen?
              @query_string || printer.print(self)
            else
              @query_string ||= printer.print(self)
            end
          else
            printer.print(self)
          end
        end

        # This creates a copy of `self`, with `new_options` applied.
        #
        # **Parameters**
        #
        # - `new_options` (`Hash`)
        #
        # **Returns**
        #
        # - `AbstractNode` — a shallow copy of `self`
        #
        # :call-seq:
        #   merge(Hash new_options) -> AbstractNode
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
            prev_idx = new_children.index(previous_child) #: as Integer
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
          # **Returns**
          #
          # - `Symbol` — the method that GraphQL::Language::Visitor calls for this kind of node
          attr_reader :visit_method

          attr_accessor :children_method_name

          # Add a default `.visit_method` and `.children_method_name` using the class name
          def inherited(child_class)
            super
            name_underscored = child_class.name
              .split("::").last
              .gsub(/([a-z])([A-Z])/,'\1_\2') # insert underscores
              .downcase # remove caps

            child_class.instance_variable_set(:@visit_method, :"on_#{name_underscored}")
            child_class.children_method_name = :"#{name_underscored}s"
          end

          # **Returns**
          #
          # - `Hash{Symbol => Class, nil}, nil` — child reader methods and the kind of node each one returns, if known
          def children_of_type
            @children_methods
          end
        end
      end

      # Base class for non-null type names and list type names
      class WrapperType < AbstractNode
        def visit_method
          :on_wrapper_type
        end

        attr_reader :of_type

        def scalars
          @scalars ||= [@of_type].freeze
        end

        def initialize(of_type: nil, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @of_type = of_type
        end

        def self.from_a(filename, line, col, of_type, comment: nil)
          self.new(filename: filename, line: line, col: col, of_type: of_type)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @of_type,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @of_type = values
        end

        @children_methods = {}.freeze
      end

      # Base class for nodes whose only value is a name (no child nodes or other scalars)
      class NameOnlyNode < AbstractNode
        def visit_method
          :on_name_only_node
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        def initialize(name: nil, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
        end

        def self.from_a(filename, line, col, name, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name = values
        end

        @children_methods = {}.freeze
      end

      # A key-value pair for a field's inputs
      class Argument < AbstractNode
        def visit_method
          :on_argument
        end

        attr_reader :name, :value

        def scalars
          @scalars ||= [@name, @value].freeze
        end

        def initialize(name: nil, value: nil, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @value = value
        end

        def self.from_a(filename, line, col, name, value, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, value: value)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @value,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @value = values
        end

        @children_methods = {}.freeze

        # **Attributes**
        #
        # - `name` (`String`) — the key for this argument

        # **Attributes**
        #
        # - `value` (`String, Float, Integer, Boolean, Array, InputObject, VariableIdentifier`) — The value passed for this key

        def children
          @children ||= Array(value).flatten.tap { _1.select! { |v| v.is_a?(AbstractNode) } }
        end
      end

      class Directive < AbstractNode
        def visit_method
          :on_directive
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :arguments

        def merge_argument(**node_opts)
          merge(arguments: arguments + [GraphQL::Language::Nodes::Argument.new(**node_opts)])
        end

        alias :children arguments

        def initialize(name: nil, arguments: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @arguments = arguments.freeze
        end

        def self.from_a(filename, line, col, name, arguments, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, arguments: arguments)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @arguments,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @arguments = values
        end

        @children_methods = {
          arguments: GraphQL::Language::Nodes::Argument,
        }.freeze
      end

      class DirectiveLocation < NameOnlyNode
        def visit_method
          :on_directive_location
        end

      end

      class DirectiveDefinition < AbstractNode
        def visit_method
          :on_directive_definition
        end

        attr_reader :description
        attr_reader :name, :repeatable

        def scalars
          @scalars ||= [@name, @repeatable].freeze
        end

        attr_reader :arguments
        attr_reader :locations

        def merge_argument(**node_opts)
          merge(arguments: arguments + [GraphQL::Language::Nodes::Argument.new(**node_opts)])
        end

        def merge_location(**node_opts)
          merge(locations: locations + [GraphQL::Language::Nodes::DirectiveLocation.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@arguments.empty? || !@locations.empty?
              new_children = []
              new_children.concat(@arguments)
              new_children.concat(@locations)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, repeatable: nil, description: nil, arguments: NO_CHILDREN, locations: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @repeatable = repeatable
          @description = description && -description
          @arguments = arguments.freeze
          @locations = locations.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, repeatable, description, arguments, locations, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, repeatable: repeatable, description: description, arguments: arguments, locations: locations)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @repeatable,
            @description,
            @arguments,
            @locations,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @repeatable, @description, @arguments, @locations = values
        end

        @children_methods = {
          arguments: GraphQL::Language::Nodes::Argument,
          locations: GraphQL::Language::Nodes::DirectiveLocation,
        }.freeze
        self.children_method_name = :definitions
      end

      # An enum value. The string is available as `name`.
      class Enum < NameOnlyNode
        def visit_method
          :on_enum
        end

      end

      # A null value literal.
      class NullValue < NameOnlyNode
        def visit_method
          :on_null_value
        end

      end

      # A single selection in a GraphQL query.
      class Field < AbstractNode
        def visit_method
          :on_field
        end

        def initialize(name: nil, arguments: NONE, directives: NONE, selections: NONE, field_alias: nil, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @name = name
          @arguments = arguments || NONE
          @directives = directives || NONE
          @selections = selections || NONE
          # oops, alias is a keyword:
          @alias = field_alias
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
        end

        def self.from_a(filename, line, col, field_alias, name, arguments, directives, selections) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, field_alias: field_alias, name: name, arguments: arguments, directives: directives, selections: selections)
        end

        def marshal_dump
          [line, col, @filename, @name, @arguments, @directives, @selections, @alias]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @arguments, @directives, @selections, @alias = values
        end

        attr_reader :name, :alias

        def scalars
          @scalars ||= [@name, @alias].freeze
        end

        attr_reader :arguments
        attr_reader :selections
        attr_reader :directives

        def merge_argument(**node_opts)
          merge(arguments: arguments + [GraphQL::Language::Nodes::Argument.new(**node_opts)])
        end

        def merge_selection(**node_opts)
          merge(selections: selections + [GraphQL::Language::Nodes::Field.new(**node_opts)])
        end

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@arguments.empty? || !@selections.empty? || !@directives.empty?
              new_children = []
              new_children.concat(@arguments)
              new_children.concat(@selections)
              new_children.concat(@directives)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        @children_methods = {
          arguments: GraphQL::Language::Nodes::Argument,
          selections: GraphQL::Language::Nodes::Field,
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze

        # Override this because default is `:fields`
        self.children_method_name = :selections
      end

      # A reusable fragment, defined at document-level.
      class FragmentDefinition < AbstractNode
        def visit_method
          :on_fragment_definition
        end

        def initialize(name: nil, type: nil, directives: NONE, selections: NONE, filename: nil, pos: nil, source: nil, line: nil, col: nil)
          @name = name
          @type = type
          @directives = directives
          @selections = selections
          @filename  = filename
          @pos = pos
          @source = source
          @line = line
          @col = col
        end

        def self.from_a(filename, line, col, name, type, directives, selections)
          self.new(filename: filename, line: line, col: col, name: name, type: type, directives: directives, selections: selections)
        end

        def marshal_dump
          [line, col, @filename, @name, @type, @directives, @selections]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @type, @directives, @selections = values
        end

        attr_reader :name, :type

        def scalars
          @scalars ||= [@name, @type].freeze
        end

        attr_reader :selections
        attr_reader :directives

        def merge_selection(**node_opts)
          merge(selections: selections + [GraphQL::Language::Nodes::Field.new(**node_opts)])
        end

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@selections.empty? || !@directives.empty?
              new_children = []
              new_children.concat(@selections)
              new_children.concat(@directives)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        @children_methods = {
          selections: GraphQL::Language::Nodes::Field,
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze

        self.children_method_name = :definitions
      end

      # Application of a named fragment in a selection
      class FragmentSpread < AbstractNode
        def visit_method
          :on_fragment_spread
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @directives = directives.freeze
        end

        def self.from_a(filename, line, col, name, directives, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze

        self.children_method_name = :selections

        # **Attributes**
        #
        # - `name` (`String`) — The identifier of the fragment to apply, corresponds with [FragmentDefinition#name](rdoc-ref:FragmentDefinition#name)
      end

      # An unnamed fragment, defined directly in the query with `... {  }`
      class InlineFragment < AbstractNode
        def visit_method
          :on_inline_fragment
        end

        attr_reader :type

        def scalars
          @scalars ||= [@type].freeze
        end

        attr_reader :directives
        attr_reader :selections

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_selection(**node_opts)
          merge(selections: selections + [GraphQL::Language::Nodes::Field.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@selections.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@selections)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(type: nil, directives: NO_CHILDREN, selections: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @type = type
          @directives = directives.freeze
          @selections = selections.freeze
        end

        def self.from_a(filename, line, col, type, directives, selections, comment: nil)
          self.new(filename: filename, line: line, col: col, type: type, directives: directives, selections: selections)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @type,
            @directives,
            @selections,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @type, @directives, @selections = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          selections: GraphQL::Language::Nodes::Field,
        }.freeze

        self.children_method_name = :selections

        # **Attributes**
        #
        # - `type` (`String, nil`) — Name of the type this fragment applies to, or `nil` if this fragment applies to any type
      end

      # A collection of key-value inputs which may be a field argument
      class InputObject < AbstractNode
        def visit_method
          :on_input_object
        end

        attr_reader :arguments

        def merge_argument(**node_opts)
          merge(arguments: arguments + [GraphQL::Language::Nodes::Argument.new(**node_opts)])
        end

        alias :children arguments

        def initialize(arguments: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @arguments = arguments.freeze
        end

        def self.from_a(filename, line, col, arguments, comment: nil)
          self.new(filename: filename, line: line, col: col, arguments: arguments)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @arguments,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @arguments = values
        end

        @children_methods = {
          arguments: GraphQL::Language::Nodes::Argument,
        }.freeze

        # **Attributes**
        #
        # - `arguments` (`Array<Nodes::Argument>`) — A list of key-value pairs inside this input object

        # **Returns**
        #
        # - `Hash<String, Any>` — Recursively turn this input object into a Ruby Hash
        #
        # :call-seq:
        #   to_h(options=) -> Hash[String, Any]
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
        def visit_method
          :on_list_type
        end

      end

      # A non-null type definition, denoted with `...!` (used for variable type definitions)
      class NonNullType < WrapperType
        def visit_method
          :on_non_null_type
        end

      end

      # An operation-level query variable
      class VariableDefinition < AbstractNode
        def visit_method
          :on_variable_definition
        end

        attr_reader :name, :type, :default_value

        def scalars
          @scalars ||= [@name, @type, @default_value].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, type: nil, default_value: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @type = type
          @default_value = default_value
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, type, default_value, directives, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, type: type, default_value: default_value, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @type,
            @default_value,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @type, @default_value, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        # **Attributes**
        #
        # - `default_value` (`String, Integer, Float, Boolean, Array, NullValue`) — A Ruby value to use if no other value is provided

        # **Attributes**
        #
        # - `type` (`TypeName, NonNullType, ListType`) — The expected type of this value

        # **Attributes**
        #
        # - `name` (`String`) — The identifier for this variable, _without_ `$`

        self.children_method_name = :variables
      end

      # A query, mutation or subscription.
      # May be anonymous or named.
      # May be explicitly typed (eg `mutation { ... }`) or implicitly a query (eg `{ ... }`).
      class OperationDefinition < AbstractNode
        def visit_method
          :on_operation_definition
        end

        attr_reader :operation_type, :name

        def scalars
          @scalars ||= [@operation_type, @name].freeze
        end

        attr_reader :variables
        attr_reader :directives
        attr_reader :selections

        def merge_variable(**node_opts)
          merge(variables: variables + [GraphQL::Language::Nodes::VariableDefinition.new(**node_opts)])
        end

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_selection(**node_opts)
          merge(selections: selections + [GraphQL::Language::Nodes::Field.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@variables.empty? || !@directives.empty? || !@selections.empty?
              new_children = []
              new_children.concat(@variables)
              new_children.concat(@directives)
              new_children.concat(@selections)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(operation_type: nil, name: nil, variables: NO_CHILDREN, directives: NO_CHILDREN, selections: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @operation_type = operation_type
          @name = name
          @variables = variables.freeze
          @directives = directives.freeze
          @selections = selections.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, operation_type, name, variables, directives, selections, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, operation_type: operation_type, name: name, variables: variables, directives: directives, selections: selections)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @operation_type,
            @name,
            @variables,
            @directives,
            @selections,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @operation_type, @name, @variables, @directives, @selections = values
        end

        @children_methods = {
          variables: GraphQL::Language::Nodes::VariableDefinition,
          directives: GraphQL::Language::Nodes::Directive,
          selections: GraphQL::Language::Nodes::Field,
        }.freeze

        # **Attributes**
        #
        # - `variables` (`Array<VariableDefinition>`) — Variable $definitions for this operation

        # **Attributes**
        #
        # - `selections` (`Array<Field>`) — Root-level fields on this operation

        # **Attributes**
        #
        # - `operation_type` (`String, nil`) — The root type for this operation, or `nil` for implicit `"query"`

        # **Attributes**
        #
        # - `name` (`String, nil`) — The name for this operation, or `nil` if unnamed

        self.children_method_name = :definitions
      end

      # This is the AST root for normal queries
      #
      # **Examples**
      #
      # **Example: Deriving a document by parsing a string**
      #
      # ```ruby
      # document = GraphQL.parse(query_string)
      # ```
      #
      # **Example: Creating a string from a document**
      #
      # ```ruby
      # document.to_query_string
      # # { ... }
      # ```
      #
      # **Example: Creating a custom string from a document**
      #
      # ```ruby
      # class VariableScrubber < GraphQL::Language::Printer
      #   def print_argument(arg)
      #     print_string("#{arg.name}: <HIDDEN>")
      #   end
      # end
      #
      # document.to_query_string(printer: VariableScrubber.new)
      # ```
      class Document < AbstractNode
        def visit_method
          :on_document
        end

        attr_reader :definitions

        alias :children definitions

        def initialize(definitions: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @definitions = definitions.freeze
        end

        def self.from_a(filename, line, col, definitions, comment: nil)
          self.new(filename: filename, line: line, col: col, definitions: definitions)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @definitions,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @definitions = values
        end

        @children_methods = {
          definitions: nil,
        }.freeze
        # **Attributes**
        #
        # - `definitions` (`Array<OperationDefinition, FragmentDefinition>`) — top-level GraphQL units: operations or fragments

        def slice_definition(name)
          GraphQL::Language::DefinitionSlice.slice(self, name)
        end
      end

      # A type name, used for variable definitions
      class TypeName < NameOnlyNode
        def visit_method
          :on_type_name
        end

      end

      # Usage of a variable in a query. Name does _not_ include `$`.
      class VariableIdentifier < NameOnlyNode
        def visit_method
          :on_variable_identifier
        end

        self.children_method_name = :value
      end

      class SchemaDefinition < AbstractNode
        def visit_method
          :on_schema_definition
        end

        attr_reader :query, :mutation, :subscription

        def scalars
          @scalars ||= [@query, @mutation, @subscription].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(query: nil, mutation: nil, subscription: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @query = query
          @mutation = mutation
          @subscription = subscription
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, query, mutation, subscription, directives, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, query: query, mutation: mutation, subscription: subscription, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @query,
            @mutation,
            @subscription,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @query, @mutation, @subscription, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :definitions
      end

      class SchemaExtension < AbstractNode
        def visit_method
          :on_schema_extension
        end

        attr_reader :query, :mutation, :subscription

        def scalars
          @scalars ||= [@query, @mutation, @subscription].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(query: nil, mutation: nil, subscription: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @query = query
          @mutation = mutation
          @subscription = subscription
          @directives = directives.freeze
        end

        def self.from_a(filename, line, col, query, mutation, subscription, directives, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, query: query, mutation: mutation, subscription: subscription, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @query,
            @mutation,
            @subscription,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @query, @mutation, @subscription, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :definitions
      end

      class ScalarTypeDefinition < AbstractNode
        def visit_method
          :on_scalar_type_definition
        end

        attr_reader :description, :comment
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, description: nil, comment: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, description, directives, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, description: description, comment: comment, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @description,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @description, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :definitions
      end

      class ScalarTypeExtension < AbstractNode
        def visit_method
          :on_scalar_type_extension
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @directives = directives.freeze
        end

        def self.from_a(filename, line, col, name, directives, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :definitions
      end

      class InputValueDefinition < AbstractNode
        def visit_method
          :on_input_value_definition
        end

        attr_reader :description, :comment
        attr_reader :name, :type, :default_value

        def scalars
          @scalars ||= [@name, @type, @default_value].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, type: nil, default_value: nil, description: nil, comment: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @type = type
          @default_value = default_value
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, type, default_value, description, directives, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, type: type, default_value: default_value, description: description, comment: comment, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @type,
            @default_value,
            @description,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @type, @default_value, @description, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :fields
      end

      class FieldDefinition < AbstractNode
        def visit_method
          :on_field_definition
        end

        attr_reader :description, :comment
        attr_reader :name, :type

        def scalars
          @scalars ||= [@name, @type].freeze
        end

        attr_reader :arguments
        attr_reader :directives

        def merge_argument(**node_opts)
          merge(arguments: arguments + [GraphQL::Language::Nodes::InputValueDefinition.new(**node_opts)])
        end

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@arguments.empty? || !@directives.empty?
              new_children = []
              new_children.concat(@arguments)
              new_children.concat(@directives)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, type: nil, description: nil, comment: nil, arguments: NO_CHILDREN, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @type = type
          @description = description && -description
          @comment = comment
          @arguments = arguments.freeze
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, type, description, arguments, directives, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, type: type, description: description, comment: comment, arguments: arguments, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @type,
            @description,
            @arguments,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @type, @description, @arguments, @directives = values
        end

        @children_methods = {
          arguments: GraphQL::Language::Nodes::InputValueDefinition,
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
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
        def visit_method
          :on_object_type_definition
        end

        attr_reader :description, :comment
        attr_reader :name, :interfaces

        def scalars
          @scalars ||= [@name, @interfaces].freeze
        end

        attr_reader :directives
        attr_reader :fields

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_field(**node_opts)
          merge(fields: fields + [GraphQL::Language::Nodes::FieldDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@fields.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@fields)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, interfaces: nil, description: nil, comment: nil, directives: NO_CHILDREN, fields: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @interfaces = interfaces
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @fields = fields.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, interfaces, description, directives, fields, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, interfaces: interfaces, description: description, comment: comment, directives: directives, fields: fields)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @interfaces,
            @description,
            @directives,
            @fields,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @interfaces, @description, @directives, @fields = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class ObjectTypeExtension < AbstractNode
        def visit_method
          :on_object_type_extension
        end

        attr_reader :name, :interfaces

        def scalars
          @scalars ||= [@name, @interfaces].freeze
        end

        attr_reader :directives
        attr_reader :fields

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_field(**node_opts)
          merge(fields: fields + [GraphQL::Language::Nodes::FieldDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@fields.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@fields)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, interfaces: nil, directives: NO_CHILDREN, fields: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @interfaces = interfaces
          @directives = directives.freeze
          @fields = fields.freeze
        end

        def self.from_a(filename, line, col, name, interfaces, directives, fields, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, interfaces: interfaces, directives: directives, fields: fields)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @interfaces,
            @directives,
            @fields,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @interfaces, @directives, @fields = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class InterfaceTypeDefinition < AbstractNode
        def visit_method
          :on_interface_type_definition
        end

        attr_reader :description, :comment
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :interfaces
        attr_reader :directives
        attr_reader :fields

        def merge_interface(**node_opts)
          merge(interfaces: interfaces + [GraphQL::Language::Nodes::TypeName.new(**node_opts)])
        end

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_field(**node_opts)
          merge(fields: fields + [GraphQL::Language::Nodes::FieldDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@interfaces.empty? || !@directives.empty? || !@fields.empty?
              new_children = []
              new_children.concat(@interfaces)
              new_children.concat(@directives)
              new_children.concat(@fields)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, description: nil, comment: nil, interfaces: NO_CHILDREN, directives: NO_CHILDREN, fields: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @description = description && -description
          @comment = comment
          @interfaces = interfaces.freeze
          @directives = directives.freeze
          @fields = fields.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, description, interfaces, directives, fields, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, description: description, comment: comment, interfaces: interfaces, directives: directives, fields: fields)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @description,
            @interfaces,
            @directives,
            @fields,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @description, @interfaces, @directives, @fields = values
        end

        @children_methods = {
          interfaces: GraphQL::Language::Nodes::TypeName,
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class InterfaceTypeExtension < AbstractNode
        def visit_method
          :on_interface_type_extension
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :interfaces
        attr_reader :directives
        attr_reader :fields

        def merge_interface(**node_opts)
          merge(interfaces: interfaces + [GraphQL::Language::Nodes::TypeName.new(**node_opts)])
        end

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_field(**node_opts)
          merge(fields: fields + [GraphQL::Language::Nodes::FieldDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@interfaces.empty? || !@directives.empty? || !@fields.empty?
              new_children = []
              new_children.concat(@interfaces)
              new_children.concat(@directives)
              new_children.concat(@fields)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, interfaces: NO_CHILDREN, directives: NO_CHILDREN, fields: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @interfaces = interfaces.freeze
          @directives = directives.freeze
          @fields = fields.freeze
        end

        def self.from_a(filename, line, col, name, interfaces, directives, fields, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, interfaces: interfaces, directives: directives, fields: fields)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @interfaces,
            @directives,
            @fields,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @interfaces, @directives, @fields = values
        end

        @children_methods = {
          interfaces: GraphQL::Language::Nodes::TypeName,
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::FieldDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class UnionTypeDefinition < AbstractNode
        def visit_method
          :on_union_type_definition
        end

        attr_reader :description, :comment, :types
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, types: nil, description: nil, comment: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @types = types
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, types, description, directives, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, types: types, description: description, comment: comment, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @types,
            @description,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @types, @description, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :definitions
      end

      class UnionTypeExtension < AbstractNode
        def visit_method
          :on_union_type_extension
        end

        attr_reader :types
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, types: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @types = types
          @directives = directives.freeze
        end

        def self.from_a(filename, line, col, name, types, directives, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, types: types, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @types,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @types, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :definitions
      end

      class EnumValueDefinition < AbstractNode
        def visit_method
          :on_enum_value_definition
        end

        attr_reader :description, :comment
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        alias :children directives

        def initialize(name: nil, description: nil, comment: nil, directives: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, description, directives, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, description: description, comment: comment, directives: directives)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @description,
            @directives,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @description, @directives = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
        }.freeze
        self.children_method_name = :values
      end

      class EnumTypeDefinition < AbstractNode
        def visit_method
          :on_enum_type_definition
        end

        attr_reader :description, :comment
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives
        attr_reader :values

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_value(**node_opts)
          merge(values: values + [GraphQL::Language::Nodes::EnumValueDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@values.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@values)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, description: nil, comment: nil, directives: NO_CHILDREN, values: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @values = values.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, description, directives, values, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, description: description, comment: comment, directives: directives, values: values)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @description,
            @directives,
            @values,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @description, @directives, @values = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          values: GraphQL::Language::Nodes::EnumValueDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class EnumTypeExtension < AbstractNode
        def visit_method
          :on_enum_type_extension
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives
        attr_reader :values

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_value(**node_opts)
          merge(values: values + [GraphQL::Language::Nodes::EnumValueDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@values.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@values)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, directives: NO_CHILDREN, values: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @directives = directives.freeze
          @values = values.freeze
        end

        def self.from_a(filename, line, col, name, directives, values, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, directives: directives, values: values)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @directives,
            @values,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @directives, @values = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          values: GraphQL::Language::Nodes::EnumValueDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class InputObjectTypeDefinition < AbstractNode
        def visit_method
          :on_input_object_type_definition
        end

        attr_reader :description, :comment
        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives
        attr_reader :fields

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_field(**node_opts)
          merge(fields: fields + [GraphQL::Language::Nodes::InputValueDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@fields.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@fields)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, description: nil, comment: nil, directives: NO_CHILDREN, fields: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil, definition_pos: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @description = description && -description
          @comment = comment
          @directives = directives.freeze
          @fields = fields.freeze
          @definition_pos = definition_pos
        end

        def self.from_a(filename, line, col, name, description, directives, fields, comment: nil) # rubocop:disable Metrics/ParameterLists
          self.new(filename: filename, line: line, col: col, name: name, description: description, comment: comment, directives: directives, fields: fields)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @description,
            @directives,
            @fields,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @description, @directives, @fields = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::InputValueDefinition,
        }.freeze
        self.children_method_name = :definitions
      end

      class InputObjectTypeExtension < AbstractNode
        def visit_method
          :on_input_object_type_extension
        end

        attr_reader :name

        def scalars
          @scalars ||= [@name].freeze
        end

        attr_reader :directives
        attr_reader :fields

        def merge_directive(**node_opts)
          merge(directives: directives + [GraphQL::Language::Nodes::Directive.new(**node_opts)])
        end

        def merge_field(**node_opts)
          merge(fields: fields + [GraphQL::Language::Nodes::InputValueDefinition.new(**node_opts)])
        end

        def children
          @children ||= begin
            if !@directives.empty? || !@fields.empty?
              new_children = []
              new_children.concat(@directives)
              new_children.concat(@fields)
              new_children.freeze
              new_children
            else
              NO_CHILDREN
            end
          end
        end

        def initialize(name: nil, directives: NO_CHILDREN, fields: NO_CHILDREN, line: nil, col: nil, pos: nil, filename: nil, source: nil)
          @line = line
          @col = col
          @pos = pos
          @filename = filename
          @source = source
          @name = name
          @directives = directives.freeze
          @fields = fields.freeze
        end

        def self.from_a(filename, line, col, name, directives, fields, comment: nil)
          self.new(filename: filename, line: line, col: col, name: name, directives: directives, fields: fields)
        end

        def marshal_dump
          [
            line, col, # use methods here to force them to be calculated
            @filename,
            @name,
            @directives,
            @fields,
          ]
        end

        def marshal_load(values)
          @line, @col, @filename, @name, @directives, @fields = values
        end

        @children_methods = {
          directives: GraphQL::Language::Nodes::Directive,
          fields: GraphQL::Language::Nodes::InputValueDefinition,
        }.freeze
        self.children_method_name = :definitions
      end
    end
  end
end
