module GraphQL
  class Query
    class SerialExecution
      module ValueResolution
        def self.get_strategy_for_kind(kind)
          TYPE_KIND_STRATEGIES[kind] || raise("No value resolution strategy for #{kind}!")
        end

        class BaseResolution
          attr_reader :value, :field_type, :target, :parent_type,
            :irep_node, :execution_context
          def initialize(value, field_type, target, parent_type, irep_node, execution_context)
            @value = value
            @field_type = field_type
            @target = target
            @parent_type = parent_type
            @irep_node = irep_node
            @execution_context = execution_context
          end

          def result
            return nil if value.nil? || value.is_a?(GraphQL::ExecutionError)
            non_null_result
          end

          def non_null_result
            raise NotImplementedError, "Should return a value based on initialization params"
          end

          def get_strategy_for_kind(*args)
            GraphQL::Query::SerialExecution::ValueResolution.get_strategy_for_kind(*args)
          end
        end

        class ScalarResolution < BaseResolution
          # Apply the scalar's defined `coerce_result` method to the value
          def non_null_result
            field_type.coerce_result(value)
          end
        end

        class ListResolution < BaseResolution
          # For each item in the list,
          # Resolve it with the "wrapped" type of this list
          def non_null_result
            wrapped_type = field_type.of_type
            strategy_class = get_strategy_for_kind(wrapped_type.kind)
            result = value.each_with_index.map do |item, index|
              irep_node.index = index
              inner_strategy = strategy_class.new(item, wrapped_type, target, parent_type, irep_node, execution_context)
              inner_strategy.result
            end
            irep_node.index = nil
            result
          end
        end

        class HasPossibleTypeResolution < BaseResolution
          def non_null_result
            resolved_type = execution_context.schema.resolve_type(value, execution_context.query.context)
            possible_types = execution_context.schema.possible_types(field_type)

            unless resolved_type.is_a?(GraphQL::ObjectType) && possible_types.include?(resolved_type)
              raise GraphQL::UnresolvedTypeError.new(irep_node.definition_name, execution_context.schema, field_type, parent_type, resolved_type)
            end

            strategy_class = get_strategy_for_kind(resolved_type.kind)
            inner_strategy = strategy_class.new(value, resolved_type, target, parent_type, irep_node, execution_context)
            inner_strategy.result
          end
        end

        class ObjectResolution < BaseResolution
          # Resolve the selections on this object
          def non_null_result
            execution_context.strategy.selection_resolution.new(
              value,
              field_type,
              irep_node,
              execution_context
            ).result
          end
        end

        class NonNullResolution < BaseResolution
          # Get the "wrapped" type and resolve the value according to that type
          def result
            if value.nil? || value.is_a?(GraphQL::ExecutionError)
              raise GraphQL::InvalidNullError.new(parent_type.name, irep_node.definition_name, value)
            else
              wrapped_type = field_type.of_type
              strategy_class = get_strategy_for_kind(wrapped_type.kind)
              inner_strategy = strategy_class.new(value, wrapped_type, target, parent_type, irep_node, execution_context)
              inner_strategy.result
            end
          end
        end

        TYPE_KIND_STRATEGIES = {
          GraphQL::TypeKinds::SCALAR =>     ScalarResolution,
          GraphQL::TypeKinds::LIST =>       ListResolution,
          GraphQL::TypeKinds::OBJECT =>     ObjectResolution,
          GraphQL::TypeKinds::ENUM =>       ScalarResolution,
          GraphQL::TypeKinds::NON_NULL =>   NonNullResolution,
          GraphQL::TypeKinds::INTERFACE =>  HasPossibleTypeResolution,
          GraphQL::TypeKinds::UNION =>      HasPossibleTypeResolution,
        }
      end
    end
  end
end
