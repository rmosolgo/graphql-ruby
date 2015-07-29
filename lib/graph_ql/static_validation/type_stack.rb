# - Ride along with `GraphQL::Visitor`
# - Track type info, expose it to validators
class GraphQL::StaticValidation::TypeStack
  # These are jumping-off points for infering types down the tree
  TYPE_INFERRENCE_ROOTS = [
    GraphQL::Nodes::OperationDefinition,
    GraphQL::Nodes::FragmentDefinition,
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

  # @param schema [GraphQL::Schema] the schema whose types to use when climbing this document
  # @param visitor [GraphQL::Visitor] a visitor to follow & watch the types
  def initialize(schema, visitor)
    @schema = schema
    @object_types = []
    @field_definitions = []
    @directive_definitions = []
    visitor.enter << -> (node, parent) { PUSH_STRATEGIES[node.class].push(self, node) }
    visitor.leave << -> (node, parent) { PUSH_STRATEGIES[node.class].pop(self, node) }
  end

  private

  # Look up strategies by name and use singleton instance to push and pop
  PUSH_STRATEGIES = Hash.new { |hash, key| hash[key] = get_strategy_for_node_class(key) }

  def self.get_strategy_for_node_class(node_class)
    node_class_name = node_class.name.split("::").last
    strategy_key = "#{node_class_name}Strategy"
    const_defined?(strategy_key) ? const_get(strategy_key).new : NullStrategy.new
  end

  class FragmentWithTypeStrategy
    def push(stack, node)
      object_type = stack.schema.types[node.type]
      if !object_type.nil?
        object_type = object_type.kind.unwrap(object_type)
      end
      stack.object_types.push(object_type)
    end

    def pop(stack, node)
      stack.object_types.pop
    end
  end

  class FragmentDefinitionStrategy < FragmentWithTypeStrategy; end
  class InlineFragmentStrategy < FragmentWithTypeStrategy; end

  class OperationDefinitionStrategy
    def push(stack, node)
      # query or mutation
      object_type = stack.schema.public_send(node.operation_type)
      stack.object_types.push(object_type)
    end
    def pop(stack, node)
      stack.object_types.pop
    end
  end

  class FieldStrategy
    def push(stack, node)
      parent_type = stack.object_types.last
      parent_type = parent_type.kind.unwrap(parent_type)
      if parent_type.kind.fields?
        field_class = parent_type.fields[node.name]
        stack.field_definitions.push(field_class)
        if !field_class.nil?
          next_object_type = field_class.type
          stack.object_types.push(next_object_type)
        else
          stack.object_types.push(nil)
        end
      else
        stack.field_definitions.push(nil)
        stack.object_types.push(parent_type)
      end
    end

    def pop(stack, node)
      stack.field_definitions.pop
      stack.object_types.pop
    end
  end

  class DirectiveStrategy
    def push(stack, node)
      directive_defn = stack.schema.directives[node.name]
      stack.directive_definitions.push(directive_defn)
    end

    def pop(stack, node)
      stack.directive_definitions.pop
    end
  end

  # A no-op strategy (don't handle this node)
  class NullStrategy
    def push(stack, node);  end
    def pop(stack, node);   end
  end
end
