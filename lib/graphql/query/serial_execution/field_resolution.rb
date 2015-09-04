module GraphQL
  class Query
    class SerialExecution
      class FieldResolution < GraphQL::Query::BaseExecution::SelectedObjectResolution
        attr_reader :field, :arguments

        def initialize(ast_node, parent_type, target, query, execution_strategy)
          super
          @field = query.schema.get_field(parent_type, ast_node.name) || raise("No field found on #{parent_type.name} '#{parent_type}' for '#{ast_node.name}'")
          @arguments = GraphQL::Query::Arguments.new(ast_node.arguments, field.arguments, query.variables)
        end

        def result
          result_name = ast_node.alias || ast_node.name
          result_value = get_finished_value(get_raw_value)
          { result_name => result_value  }
        end

        private

        def get_finished_value(raw_value)
          if raw_value.nil?
            nil
          else
            resolved_type = field.type.kind.resolve(field.type, raw_value)
            strategy_class = GraphQL::Query::BaseExecution::ValueResolution.get_strategy_for_kind(resolved_type.kind)
            result_strategy = strategy_class.new(raw_value, resolved_type, target, parent_type, ast_node, query, execution_strategy)
            result_strategy.result
          end
        end


        def get_raw_value
          value = field.resolve(target, arguments, query.context)

          if value == GraphQL::Query::DEFAULT_RESOLVE
            begin
              value = target.public_send(ast_node.name)
            rescue NoMethodError => err
              raise("Couldn't resolve field '#{ast_node.name}' to #{target.class} '#{target}' (resulted in #{err})")
            end
          end

          value
        end
      end
    end
  end
end
