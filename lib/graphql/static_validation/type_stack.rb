# frozen_string_literal: true
module GraphQL
  module StaticValidation
    # - Ride along with `GraphQL::Language::Visitor`
    # - Track type info, expose it to validators
    class TypeStack
      # These are jumping-off points for infering types down the tree
      TYPE_INFERRENCE_ROOTS = [
        GraphQL::Language::Nodes::OperationDefinition,
        GraphQL::Language::Nodes::FragmentDefinition,
      ]

      # @return [GraphQL::Schema] the schema whose types are present in this document
      attr_reader :schema

      # When it enters an object (starting with query or mutation root), it's pushed on this stack.
      # When it exits, it's popped off.
      # @return [Array<GraphQL::ObjectType, GraphQL::Union, GraphQL::Interface>]
      attr_reader :object_types

      # When it enters a field, it's pushed on this stack (useful for nested fields, args).
      # When it exits, it's popped off.
      # @return [Array<GraphQL::Field>] fields which have been entered
      attr_reader :field_definitions

      # Directives are pushed on, then popped off while traversing the tree
      # @return [Array<GraphQL::Node::Directive>] directives which have been entered
      attr_reader :directive_definitions

      # @return [Array<GraphQL::Node::Argument>] arguments which have been entered
      attr_reader :argument_definitions

      # @return [Array<String>] fields which have been entered (by their AST name)
      attr_reader :path

      # @param schema [GraphQL::Schema] the schema whose types to use when climbing this document
      # @param visitor [GraphQL::Language::Visitor] a visitor to follow & watch the types
      def initialize(schema, visitor)
        @schema = schema
        @object_types = []
        @field_definitions = []
        @directive_definitions = []
        @argument_definitions = []
        @path = []

        PUSH_STRATEGIES.each do |node_class, strategy|
          visitor[node_class].enter << EnterWithStrategy.new(self, strategy)
          visitor[node_class].leave << LeaveWithStrategy.new(self, strategy)
        end
      end

      private


      module FragmentWithTypeStrategy
        def push(stack, node)
          object_type = if node.type
            stack.schema.get_type(node.type.name)
          else
            stack.object_types.last
          end
          if !object_type.nil?
            object_type = object_type.unwrap
          end
          stack.object_types.push(object_type)
          push_path_member(stack, node)
        end

        def pop(stack, node)
          stack.object_types.pop
          stack.path.pop
        end
      end

      module FragmentDefinitionStrategy
        extend FragmentWithTypeStrategy
        module_function
        def push_path_member(stack, node)
          stack.path.push("fragment #{node.name}")
        end
      end

      module InlineFragmentStrategy
        extend FragmentWithTypeStrategy
        module_function
        def push_path_member(stack, node)
          stack.path.push("...#{node.type ? " on #{node.type.to_query_string}" : ""}")
        end
      end

      module OperationDefinitionStrategy
        module_function
        def push(stack, node)
          # eg, QueryType, MutationType
          object_type = stack.schema.root_type_for_operation(node.operation_type)
          stack.object_types.push(object_type)
          stack.path.push("#{node.operation_type}#{node.name ? " #{node.name}" : ""}")
        end

        def pop(stack, node)
          stack.object_types.pop
          stack.path.pop
        end
      end

      module FieldStrategy
        module_function
        def push(stack, node)
          parent_type = stack.object_types.last
          parent_type = parent_type.unwrap

          field_definition = stack.schema.get_field(parent_type, node.name)
          stack.field_definitions.push(field_definition)
          if !field_definition.nil?
            next_object_type = field_definition.type
            stack.object_types.push(next_object_type)
          else
            stack.object_types.push(nil)
          end
          stack.path.push(node.alias || node.name)
        end

        def pop(stack, node)
          stack.field_definitions.pop
          stack.object_types.pop
          stack.path.pop
        end
      end

      module DirectiveStrategy
        module_function
        def push(stack, node)
          directive_defn = stack.schema.directives[node.name]
          stack.directive_definitions.push(directive_defn)
        end

        def pop(stack, node)
          stack.directive_definitions.pop
        end
      end

      module ArgumentStrategy
        module_function
        # Push `argument_defn` onto the stack.
        # It's possible that `argument_defn` will be nil.
        # Push it anyways so `pop` has something to pop.
        def push(stack, node)
          if stack.argument_definitions.last
            arg_type = stack.argument_definitions.last.type.unwrap
            if arg_type.kind.input_object?
              argument_defn = arg_type.arguments[node.name]
            else
              argument_defn = nil
            end
          elsif stack.directive_definitions.last
            argument_defn = stack.directive_definitions.last.arguments[node.name]
          elsif stack.field_definitions.last
            argument_defn = stack.field_definitions.last.arguments[node.name]
          else
            argument_defn = nil
          end
          stack.argument_definitions.push(argument_defn)
          stack.path.push(node.name)
        end

        def pop(stack, node)
          stack.argument_definitions.pop
          stack.path.pop
        end
      end

      module FragmentSpreadStrategy
        module_function
        def push(stack, node)
          stack.path.push("... #{node.name}")
        end

        def pop(stack, node)
          stack.path.pop
        end
      end

      PUSH_STRATEGIES = {
        GraphQL::Language::Nodes::FragmentDefinition => FragmentDefinitionStrategy,
        GraphQL::Language::Nodes::InlineFragment => InlineFragmentStrategy,
        GraphQL::Language::Nodes::FragmentSpread => FragmentSpreadStrategy,
        GraphQL::Language::Nodes::Argument => ArgumentStrategy,
        GraphQL::Language::Nodes::Field => FieldStrategy,
        GraphQL::Language::Nodes::Directive => DirectiveStrategy,
        GraphQL::Language::Nodes::OperationDefinition => OperationDefinitionStrategy,
      }

      class EnterWithStrategy
        def initialize(stack, strategy)
          @stack = stack
          @strategy = strategy
        end

        def call(node, parent)
          @strategy.push(@stack, node)
        end
      end

      class LeaveWithStrategy
        def initialize(stack, strategy)
          @stack = stack
          @strategy = strategy
        end

        def call(node, parent)
          @strategy.pop(@stack, node)
        end
      end
    end
  end
end
