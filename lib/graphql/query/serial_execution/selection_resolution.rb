module GraphQL
  class Query
    class SerialExecution
      class SelectionResolution
        attr_reader :target, :type, :selections, :execution_context, :depth

        def initialize(target, type, selections, execution_context, depth: 1)
          @target = target
          @type = type
          @selections = selections
          @execution_context = execution_context
          @depth = depth
          execution_context.depth_check(depth)
        end

        def result
          flatten_and_merge_selections(selections)
            .values
            .reduce({}) { |result, ast_node|
              result.merge(resolve_field(ast_node))
            }
        rescue GraphQL::InvalidNullError => err
          execution_context.add_error(err) unless err.parent_error?
          nil
        end

        private

        def flatten_selection(ast_node)
          strategy_method = STRATEGIES[ast_node.class]
          send(strategy_method, ast_node)
        end

        STRATEGIES = {
          GraphQL::Language::Nodes::Field => :flatten_field,
          GraphQL::Language::Nodes::InlineFragment => :flatten_inline_fragment,
          GraphQL::Language::Nodes::FragmentSpread => :flatten_fragment_spread,
        }

        def flatten_field(ast_node)
          result_name = ast_node.alias || ast_node.name
          { result_name => ast_node }
        end

        def flatten_inline_fragment(ast_node)
          chain = GraphQL::Query::DirectiveChain.new(ast_node, execution_context.query) {
            flatten_fragment(ast_node)
          }
          chain.result
        end

        def flatten_fragment_spread(ast_node)
          ast_fragment_defn = execution_context.get_fragment(ast_node.name)
          chain = GraphQL::Query::DirectiveChain.new(ast_node, execution_context.query) {
            flatten_fragment(ast_fragment_defn)
          }
          chain.result
        end

        def flatten_fragment(ast_fragment)
          return {} unless fragment_type_can_apply?(ast_fragment)
          flatten_and_merge_selections(ast_fragment.selections)
        end

        def fragment_type_can_apply?(ast_fragment)
          child_type = execution_context.get_type(ast_fragment.type)
          resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
          !resolved_type.nil?
        end

        def merge_fields(field1, field2)
          field_type = execution_context.get_field(type, field2.name).type.unwrap
          return field2 unless field_type.kind.fields?

          # create a new ast field node merging selections from each field.
          # Because of static validation, we can assume that name, alias,
          # arguments, and directives are exactly the same for fields 1 and 2.
          GraphQL::Language::Nodes::Field.new(
            name: field2.name,
            alias: field2.alias,
            arguments: field2.arguments,
            directives: field2.directives,
            selections: field1.selections + field2.selections
          )
        end

        def resolve_field(ast_node)
          chain = GraphQL::Query::DirectiveChain.new(ast_node, execution_context.query) {
            execution_context.strategy.field_resolution.new(
              ast_node,
              type,
              target,
              execution_context,
              depth: depth + 1
            ).result
          }
          chain.result
        end

        def merge_into_result(memo, selection)
          name = if selection.respond_to?(:alias)
            selection.alias || selection.name
          else
            selection.name
          end

          memo[name] = if memo.has_key?(name)
            merge_fields(memo[name], selection)
          else
            selection
          end
        end

        def flatten_and_merge_selections(selections)
          selections.reduce({}) do |result, ast_node|
            flattened_selections = flatten_selection(ast_node)
            flattened_selections.each do |name, selection|
              merge_into_result(result, selection)
            end
            result
          end
        end
      end
    end
  end
end
