# - Ride along with `GraphQL::Visitor`
# - Track type info, expose it to validators
class GraphQL::StaticValidation::TypeStack
  # These are jumping-off points for infering types down the tree
  TYPE_INFERRENCE_ROOTS = [
    GraphQL::Nodes::OperationDefinition,
    GraphQL::Nodes::FragmentDefinition,
  ]

  attr_reader :schema
  def initialize(schema, visitor)
    @schema = schema
    visitor.enter << -> (node, parent) { push_type_for_node(node) }
    visitor.leave << -> (node, parent) { pop_type_for_node(node) }
  end

  def object_types
    @object_types ||= []
  end

  def field_definitions
    @field_definitions ||= []
  end

  private

  def push_type_for_node(node)
    strategy = PUSH_STRATEGIES[node.class]
    if strategy
      # p "PUSHING #{node.class}"
      strategy.push(self, node)
    else
      # p "NOT pushing #{node.class}"
    end
  rescue StandardError => err
    raise RuntimeError, "#{node.class} / #{object_types.length} } (#{err})"
  end


  def pop_type_for_node(node)
    strategy = PUSH_STRATEGIES[node.class]
    if strategy
      strategy.pop(self, node)
    end
  end

  class FragmentDefinitionStrategy
    def push(stack, node)
      object_type = stack.schema.types[node.type]
      object_type = object_type.kind.unwrap(object_type)
      stack.object_types.push(object_type)
    end

    def pop(stack, node)
      stack.object_types.pop
    end
  end

  class InlineFragmentStrategy
    def push(stack, node)
      object_type = stack.schema.types[node.type]
      object_type = object_type.kind.unwrap(object_type)
      stack.object_types.push(object_type)
    end

    def pop(stack, node)
      stack.object_types.pop
    end
  end

  class OperationDefinitionStrategy
    def push(stack, node)
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
        stack.field_definitions.push(parent_type)
        stack.object_types.push(parent_type)
      end
    end

    def pop(stack, node)
      stack.field_definitions.pop
      stack.object_types.pop
    end
  end

  def self.get_strategy_for_node_class(node_class)
    node_class_name = node_class.name.split("::").last
    strategy_key = "#{node_class_name}Strategy"
    const_defined?(strategy_key) ? const_get(strategy_key).new : nil
  end

  # Look up strategies by name and use singleton instance to push and pop
  PUSH_STRATEGIES = Hash.new { |hash, key| hash[key] = get_strategy_for_node_class(key) }
end
