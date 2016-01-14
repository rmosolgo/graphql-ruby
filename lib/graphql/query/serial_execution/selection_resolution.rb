module GraphQL
  class Query
    class SerialExecution
      class SelectionResolution
        attr_reader :target, :type, :selections, :query, :execution_strategy

        def initialize(target, type, selections, query, execution_strategy)
          @target = target
          @type = type
          @selections = selections
          @query = query
          @execution_strategy = execution_strategy
        end

        def result
          # In a first pass, we flatten the selection by merging in fields from
          # any fragments - this prevents us from resolving the same fields
          # more than one time in cases where fragments repeat fields.
          # Then, In a second pass, we resolve the flattened set of fields
          selections
            .reduce({}){|memo, ast_node|
              flattened_selections = flatten_selection(ast_node)
              flattened_selections.each do |name, selection|
                merge_into_result(memo, selection)
              end
              memo
            }
            .values
            .reduce({}){|memo, ast_node|
              memo.merge(resolve_field(ast_node))
            }
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
          return { result_name => ast_node }
        end

        def flatten_inline_fragment(ast_node)
          chain = GraphQL::Query::DirectiveChain.new(ast_node, query) {
            flatten_fragment(ast_node)
          }
          chain.result
        end

        def flatten_fragment_spread(ast_node)
          ast_fragment_defn = query.fragments[ast_node.name]
          chain = GraphQL::Query::DirectiveChain.new(ast_node, query) {
            flatten_fragment(ast_fragment_defn)
          }
          chain.result
        end

        def flatten_fragment(ast_fragment)
          if !fragment_type_can_apply?(ast_fragment)
            return {}
          end

          flat_result = {}
          ast_fragment.selections.each do |selection|
            flat_selection = flatten_selection(selection)
            flat_selection.each do |name, selection|
              merge_into_result(flat_result, selection)
            end
          end
          flat_result
        end

        def fragment_type_can_apply?(ast_fragment)
          child_type = query.schema.types[ast_fragment.type]
          resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
          !resolved_type.nil?
        end

        def merge_fields(field1, field2)
          field_type = query.schema.get_field(type, field2.name).type.unwrap

          if field_type.kind.fields?
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
          else
            field2
          end
        end

        def resolve_field(ast_node)
          chain = GraphQL::Query::DirectiveChain.new(ast_node, query) {
            execution_strategy.field_resolution.new(ast_node, type, target, query, execution_strategy).result
          }
          chain.result
        end

        def merge_into_result(memo, selection)
          name = if selection.respond_to?(:alias)
            selection.alias || selection.name
          else
            selection.name
          end

          if memo.has_key?(name)
            memo[name] = merge_fields(memo[name], selection)
          else
            memo[name] = selection
          end
        end
      end
    end
  end
end
