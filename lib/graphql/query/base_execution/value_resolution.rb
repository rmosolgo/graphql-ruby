module GraphQL
  class Query
    class BaseExecution
      module ValueResolution
        def self.get_strategy_for_kind(kind)
          TYPE_KIND_STRATEGIES[kind] || raise("No value resolution strategy for #{kind}!")
        end

        class BaseResolution
          attr_reader :value, :field_type, :target, :parent_type,
            :ast_field, :query, :execution_strategy
          def initialize(value, field_type, target, parent_type, ast_field, query, execution_strategy)
            @value = value
            @field_type = field_type
            @target = target
            @parent_type = parent_type
            @ast_field = ast_field
            @query = query
            @execution_strategy = execution_strategy
          end

          def result
            raise NotImplementedError, "Should return a value based on initialization params"
          end

          def get_strategy_for_kind(*args)
            GraphQL::Query::BaseExecution::ValueResolution.get_strategy_for_kind(*args)
          end
        end

        class ScalarResolution < BaseResolution
          def result
            field_type.coerce(value)
          end
        end

        class ListResolution < BaseResolution
          def result
            wrapped_type = field_type.of_type
            value.map do |item|
              resolved_type = wrapped_type.kind.resolve(wrapped_type, item)
              strategy_class = get_strategy_for_kind(resolved_type.kind)
              inner_strategy = strategy_class.new(item, resolved_type, target, parent_type, ast_field, query, execution_strategy)
              inner_strategy.result
            end
          end
        end

        class ObjectResolution < BaseResolution
          def result
            resolver = execution_strategy.selection_resolution.new(value, field_type, ast_field.selections, query, execution_strategy)
            resolver.result
          end
        end

        class EnumResolution < BaseResolution
          def result
             value.to_s
          end
        end

        class NonNullResolution < BaseResolution
          def result
            wrapped_type = field_type.of_type
            resolved_type = wrapped_type.kind.resolve(wrapped_type, value)
            strategy_class = get_strategy_for_kind(resolved_type.kind)
            inner_strategy = strategy_class.new(value, resolved_type, target, parent_type, ast_field, query, execution_strategy)
            inner_strategy.result
          end
        end

        TYPE_KIND_STRATEGIES = {
          GraphQL::TypeKinds::SCALAR =>     ScalarResolution,
          GraphQL::TypeKinds::LIST =>       ListResolution,
          GraphQL::TypeKinds::OBJECT =>     ObjectResolution,
          GraphQL::TypeKinds::ENUM =>       EnumResolution,
          GraphQL::TypeKinds::NON_NULL =>   NonNullResolution,
        }
      end
    end
  end
end
