# frozen_string_literal: true
# typed: strict
module GraphQL
  module StaticValidation
    class BaseVisitor < GraphQL::Language::StaticVisitor
      #: (GraphQL::Language::Nodes::Document document, GraphQL::StaticValidation::ValidationContext context) -> void
      def initialize(document, context)
        @path = [] #: Array[String | Integer]
        @path_depth = 0 #: Integer
        @current_object_type = nil #: GraphQL::Schema::Member::type_definition?
        @parent_object_type = nil #: GraphQL::Schema::Member::type_definition?
        @current_field_definition = nil #: GraphQL::Schema::Field?
        @current_argument_definition = nil #: GraphQL::Schema::Argument?
        @parent_argument_definition = nil #: GraphQL::Schema::Argument?
        @current_directive_definition = nil #: singleton(GraphQL::Schema::Directive)?
        @context = context #: GraphQL::StaticValidation::ValidationContext
        @types = context.types #: GraphQL::Schema::Visibility::Profile | GraphQL::Schema::Warden::VisibilityProfile
        @schema = context.schema #: singleton(GraphQL::Schema)
        @inline_fragment_paths = {} #: Hash[String, String]
        @field_unwrapped_types = {}.compare_by_identity #: Hash[GraphQL::Schema::Field, GraphQL::Schema::Member::type_definition]
        @child_positions = {}.compare_by_identity #: Hash[GraphQL::Language::Nodes::AbstractNode, Hash[GraphQL::Language::Nodes::AbstractNode, Integer]]
        super(document)
      end

      #: GraphQL::StaticValidation::ValidationContext
      attr_reader :context

      # **Returns**
      #
      # - `Array<String>` — The nesting of the current position in the AST
      #
      # :call-seq:
      #   path() -> Array[String]
      #: () -> Array[String | Integer]
      def path
        @path[0, @path_depth] #: as !nil
      end

      # Build a class to visit the AST and perform validation,
      # or use a pre-built class if rules is `ALL_RULES` or empty.
      #
      # **Parameters**
      #
      # - `rules` (`Array<Module, Class>`)
      #
      # **Returns**
      #
      # - `Class` — A class for validating `rules` during visitation
      #
      # :call-seq:
      #   including_rules(Array[Module | Class] rules) -> Class
      #: (Array[Module[untyped]]) -> singleton(GraphQL::StaticValidation::BaseVisitor)
      def self.including_rules(rules)
        if rules.empty?
          # It's not doing _anything?!?_
          BaseVisitor
        elsif rules == ALL_RULES
          InterpreterVisitor
        else
          visitor_class = Class.new(self) do
            include(GraphQL::StaticValidation::DefinitionDependencies)
          end

          rules.reverse_each do |r|
            # If it's a class, it gets attached later.
            if !r.is_a?(Class)
              visitor_class.include(r)
            end
          end

          visitor_class.include(ContextMethods)
          visitor_class
        end
      end

      #--
      # @requires_ancestor: GraphQL::StaticValidation::BaseVisitor
      module ContextMethods
        # BaseVisitor#initialize sets these. They're re-assigned here so Sorbet knows their types in this module,
        # because the hooks below use them directly instead of calling the readers on every node.
        #: (GraphQL::Language::Nodes::Document document, GraphQL::StaticValidation::ValidationContext context) -> void
        def initialize(document, context)
          super
          @path = path_parts #: Array[String | Integer]
          @path_depth = path_depth #: Integer
          @types = types #: GraphQL::Schema::Visibility::Profile | GraphQL::Schema::Warden::VisibilityProfile
          @inline_fragment_paths = inline_fragment_paths #: Hash[String, String]
          @field_unwrapped_types = field_unwrapped_types #: Hash[GraphQL::Schema::Field, GraphQL::Schema::Member::type_definition]
          @child_positions = child_positions_by_parent #: Hash[GraphQL::Language::Nodes::AbstractNode, Hash[GraphQL::Language::Nodes::AbstractNode, Integer]]
        end

        #: (GraphQL::Language::Nodes::OperationDefinition node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_operation_definition(node, parent)
          object_type = schema.root_type_for_operation(node.operation_type)
          prev_parent_ot = @parent_object_type
          @parent_object_type = @current_object_type #: GraphQL::Schema::Member::type_definition?
          @current_object_type = object_type #: GraphQL::Schema::Member::type_definition?
          path_depth = @path_depth
          @path[path_depth] = "#{node.operation_type}#{node.name ? " #{node.name}" : ""}"
          @path_depth = path_depth + 1
          super
          @current_object_type = @parent_object_type
          @parent_object_type = prev_parent_ot
          @path_depth = path_depth
        end

        #: (GraphQL::Language::Nodes::FragmentDefinition node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_fragment_definition(node, parent)
          # The type is always present when parsed, but may be missing on a hand-built node:
          fragment_type = node.type #: GraphQL::Language::Nodes::TypeName?
          object_type = if fragment_type
            @types.type(fragment_type.name)
          else
            @current_object_type
          end
          prev_parent_ot = @parent_object_type
          @parent_object_type = @current_object_type
          @current_object_type = object_type
          path_depth = @path_depth
          @path[path_depth] = "fragment #{node.name}"
          @path_depth = path_depth + 1
          super
          @current_object_type = @parent_object_type
          @parent_object_type = prev_parent_ot
          @path_depth = path_depth
        end

        INLINE_FRAGMENT_NO_TYPE = "..." #: String

        #: (GraphQL::Language::Nodes::InlineFragment node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_inline_fragment(node, parent)
          path_depth = @path_depth
          if (node_type = node.type)
            object_type = @types.type(node_type.name)
            @path[path_depth] = @inline_fragment_paths[node_type.name] ||= -"... on #{node_type.to_query_string}"
            @path_depth = path_depth + 1
          else
            object_type = @current_object_type
            @path[path_depth] = INLINE_FRAGMENT_NO_TYPE
            @path_depth = path_depth + 1
          end
          prev_parent_ot = @parent_object_type
          @parent_object_type = @current_object_type
          @current_object_type = object_type
          super
          @current_object_type = @parent_object_type
          @parent_object_type = prev_parent_ot
          @path_depth = path_depth
        end

        #: (GraphQL::Language::Nodes::Field node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_field(node, parent)
          parent_type = @current_object_type
          field_definition = @types.field(parent_type, node.name)
          prev_field_definition = @current_field_definition
          @current_field_definition = field_definition #: GraphQL::Schema::Field?
          prev_parent_ot = @parent_object_type
          @parent_object_type = @current_object_type
          if field_definition
            @current_object_type = @field_unwrapped_types[field_definition] ||= field_definition.type.unwrap
          else
            @current_object_type = nil
          end
          path_depth = @path_depth
          @path[path_depth] = node.alias || node.name
          @path_depth = path_depth + 1
          super
          @current_field_definition = prev_field_definition
          @current_object_type = @parent_object_type
          @parent_object_type = prev_parent_ot
          @path_depth = path_depth
        end

        #: (GraphQL::Language::Nodes::Directive node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_directive(node, parent)
          directive_defn = context.schema_directives[node.name]
          prev_directive_definition = @current_directive_definition
          @current_directive_definition = directive_defn #: singleton(GraphQL::Schema::Directive)?
          super
          @current_directive_definition = prev_directive_definition
        end

        #: (GraphQL::Language::Nodes::Argument node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_argument(node, parent)
          argument_defn = if (arg = @current_argument_definition)
            arg_type = arg.type.unwrap
            if arg_type.kind.input_object?
              @types.argument(arg_type, node.name)
            else
              nil
            end
          elsif (directive_defn = @current_directive_definition)
            @types.argument(directive_defn, node.name)
          elsif (field_defn = @current_field_definition)
            @types.argument(field_defn, node.name)
          else
            nil
          end

          prev_parent = @parent_argument_definition
          @parent_argument_definition = @current_argument_definition #: GraphQL::Schema::Argument?
          @current_argument_definition = argument_defn #: GraphQL::Schema::Argument?
          path_depth = @path_depth
          @path[path_depth] = node.name
          @path_depth = path_depth + 1
          super
          @current_argument_definition = @parent_argument_definition
          @parent_argument_definition = prev_parent
          @path_depth = path_depth
          @child_positions.delete(node)
        end

        #: (GraphQL::Language::Nodes::FragmentSpread node, GraphQL::Language::Nodes::AbstractNode? parent) -> void
        def on_fragment_spread(node, parent)
          path_depth = @path_depth
          @path[path_depth] = "... #{node.name}"
          @path_depth = path_depth + 1
          super
          @path_depth = path_depth
        end

        #: (GraphQL::Language::Nodes::InputObject node, GraphQL::Language::Nodes::AbstractNode parent) -> void
        def on_input_object(node, parent)
          arg_defn = @current_argument_definition
          if arg_defn && arg_defn.type.list?
            path_depth = @path_depth
            @path[path_depth] = child_positions(parent)[node] #: as !nil
            @path_depth = path_depth + 1
            super
            @path_depth = path_depth
          else
            super
          end
        end

        #: (GraphQL::Language::Nodes::AbstractNode parent) -> Hash[GraphQL::Language::Nodes::AbstractNode, Integer]
        def child_positions(parent)
          @child_positions[parent] ||= begin
            positions = {}.compare_by_identity #: Hash[GraphQL::Language::Nodes::AbstractNode, Integer]
            parent.children.each_with_index { |child, index| positions[child] ||= index }
            positions
          end
        end

        # **Returns**
        #
        # - `GraphQL::BaseType` — The current object type
        #
        # :call-seq:
        #   type_definition() -> GraphQL::BaseType
        #: () -> GraphQL::Schema::Member::type_definition?
        def type_definition
          @current_object_type
        end

        # **Returns**
        #
        # - `GraphQL::BaseType` — The type which the current type came from
        #
        # :call-seq:
        #   parent_type_definition() -> GraphQL::BaseType
        #: () -> GraphQL::Schema::Member::type_definition?
        def parent_type_definition
          @parent_object_type
        end

        # **Returns**
        #
        # - `GraphQL::Field, nil` — The most-recently-entered GraphQL::Field, if currently inside one
        #
        # :call-seq:
        #   field_definition() -> GraphQL::Field | nil
        #: () -> GraphQL::Schema::Field?
        def field_definition
          @current_field_definition
        end

        # **Returns**
        #
        # - `GraphQL::Directive, nil` — The most-recently-entered GraphQL::Directive, if currently inside one
        #
        # :call-seq:
        #   directive_definition() -> GraphQL::Directive | nil
        #: () -> singleton(GraphQL::Schema::Directive)?
        def directive_definition
          @current_directive_definition
        end

        # **Returns**
        #
        # - `GraphQL::Argument, nil` — The most-recently-entered GraphQL::Argument, if currently inside one
        #
        # :call-seq:
        #   argument_definition() -> GraphQL::Argument | nil
        #: () -> GraphQL::Schema::Argument?
        def argument_definition
          # Return the parent argument definition (not the current one).
          @parent_argument_definition
        end

        private

      end

      private

      # These readers expose the visitor's state to `ContextMethods` and to rule modules.
      # (Sorbet doesn't let a module see a class's instance variables, even with `@requires_ancestor`.)

      #: GraphQL::Schema::Visibility::Profile | GraphQL::Schema::Warden::VisibilityProfile
      attr_reader :types

      #: singleton(GraphQL::Schema)
      attr_reader :schema

      # The path entries for every level visited so far. Only the first `path_depth` of them are current; see [path](rdoc-ref:#path).
      #: () -> Array[String | Integer]
      def path_parts
        @path
      end

      #: Integer
      attr_accessor :path_depth

      #: Hash[String, String]
      attr_reader :inline_fragment_paths

      #: Hash[GraphQL::Schema::Field, GraphQL::Schema::Member::type_definition]
      attr_reader :field_unwrapped_types

      #: () -> Hash[GraphQL::Language::Nodes::AbstractNode, Hash[GraphQL::Language::Nodes::AbstractNode, Integer]]
      def child_positions_by_parent
        @child_positions
      end

      #: (GraphQL::StaticValidation::Error error, ?path: Array[String | Integer]?) -> void
      def add_error(error, path: nil)
        if @context.too_many_errors?
          throw :too_many_validation_errors
        end
        error.path ||= (path || @path[0, @path_depth])
        context.errors << error
      end

    end
  end
end
