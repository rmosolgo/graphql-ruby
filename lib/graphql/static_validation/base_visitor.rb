# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class BaseVisitor < GraphQL::Language::StaticVisitor
      def initialize(document, context)
        @path = []
        @object_types = []
        @current_field_definition = nil
        @current_argument_definition = nil
        @parent_argument_definition = nil
        @current_directive_definition = nil
        @context = context
        @types = context.query.types
        @schema = context.schema
        @inline_fragment_paths = {}
        @field_unwrapped_types = {}.compare_by_identity
        super(document)
      end

      attr_reader :context

      # @return [Array<GraphQL::ObjectType>] Types whose scope we've entered
      attr_reader :object_types

      # @return [Array<String>] The nesting of the current position in the AST
      def path
        @path.dup
      end

      # Build a class to visit the AST and perform validation,
      # or use a pre-built class if rules is `ALL_RULES` or empty.
      # @param rules [Array<Module, Class>]
      # @return [Class] A class for validating `rules` during visitation
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

      module ContextMethods
        def on_operation_definition(node, parent)
          object_type = @schema.root_type_for_operation(node.operation_type)
          @object_types.push(object_type)
          @path.push("#{node.operation_type}#{node.name ? " #{node.name}" : ""}")
          super
          @object_types.pop
          @path.pop
        end

        def on_fragment_definition(node, parent)
          on_fragment_with_type(node) do
            @path.push("fragment #{node.name}")
            super
          end
        end

        INLINE_FRAGMENT_NO_TYPE = "..."

        def on_inline_fragment(node, parent)
          on_fragment_with_type(node) do
            if node.type
              @path.push(@inline_fragment_paths[node.type.name] ||= -"... on #{node.type.to_query_string}")
            else
              @path.push(INLINE_FRAGMENT_NO_TYPE)
            end
            super
          end
        end

        def on_field(node, parent)
          parent_type = @object_types.last
          field_definition = @types.field(parent_type, node.name)
          prev_field_definition = @current_field_definition
          @current_field_definition = field_definition
          if field_definition
            @object_types.push(@field_unwrapped_types[field_definition] ||= field_definition.type.unwrap)
          else
            @object_types.push(nil)
          end
          @path.push(node.alias || node.name)
          super
          @current_field_definition = prev_field_definition
          @object_types.pop
          @path.pop
        end

        def on_directive(node, parent)
          directive_defn = @context.schema_directives[node.name]
          prev_directive_definition = @current_directive_definition
          @current_directive_definition = directive_defn
          super
          @current_directive_definition = prev_directive_definition
        end

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
          @parent_argument_definition = @current_argument_definition
          @current_argument_definition = argument_defn
          @path.push(node.name)
          super
          @current_argument_definition = @parent_argument_definition
          @parent_argument_definition = prev_parent
          @path.pop
        end

        def on_fragment_spread(node, parent)
          @path.push("... #{node.name}")
          super
          @path.pop
        end

        def on_input_object(node, parent)
          arg_defn = @current_argument_definition
          if arg_defn && arg_defn.type.list?
            @path.push(parent.children.index(node))
            super
            @path.pop
          else
            super
          end
        end

        # @return [GraphQL::BaseType] The current object type
        def type_definition
          @object_types.last
        end

        # @return [GraphQL::BaseType] The type which the current type came from
        def parent_type_definition
          @object_types[-2]
        end

        # @return [GraphQL::Field, nil] The most-recently-entered GraphQL::Field, if currently inside one
        def field_definition
          @current_field_definition
        end

        # @return [GraphQL::Directive, nil] The most-recently-entered GraphQL::Directive, if currently inside one
        def directive_definition
          @current_directive_definition
        end

        # @return [GraphQL::Argument, nil] The most-recently-entered GraphQL::Argument, if currently inside one
        def argument_definition
          # Return the parent argument definition (not the current one).
          @parent_argument_definition
        end

        private

        def on_fragment_with_type(node)
          object_type = if node.type
            @types.type(node.type.name)
          else
            @object_types.last
          end
          @object_types.push(object_type)
          yield(node)
          @object_types.pop
          @path.pop
        end
      end

      private

      def add_error(error, path: nil)
        if @context.too_many_errors?
          throw :too_many_validation_errors
        end
        error.path ||= (path || @path.dup)
        context.errors << error
      end

    end
  end
end
