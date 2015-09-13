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
              flatten_selection(ast_node).each do |name, selection|
                if memo.has_key? name
                  memo[name] = merge_fields(memo[name], selection)
                else
                  memo[name] = selection
                end
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
          return {(ast_node.alias || ast_node.name) => ast_node} if ast_node.is_a?(GraphQL::Language::Nodes::Field)

          ast_fragment = get_fragment(ast_node)
          return {} unless fragment_type_can_apply?(ast_fragment)

          chain = GraphQL::Query::DirectiveChain.new(ast_node, query) {
            ast_fragment.selections.reduce({}) do |memo, selection|
              memo.merge(flatten_selection(selection))
            end
          }

          chain.result || {}
        end

        def get_fragment(ast_node)
          if ast_node.is_a? GraphQL::Language::Nodes::FragmentSpread
            query.fragments[ast_node.name]
          elsif ast_node.is_a? GraphQL::Language::Nodes::InlineFragment
            ast_node
          else
            raise 'Unrecognized fragment node'
          end
        end

        def fragment_type_can_apply?(ast_fragment)
          child_type = query.schema.types[ast_fragment.type]
          resolved_type = GraphQL::Query::TypeResolver.new(target, child_type, type).type
          !resolved_type.nil?
        end

        def merge_fields(field1, field2)
          field_type = query.schema.get_field(type, field2.name).type.unwrap

          if field_type.is_a?(GraphQL::ObjectType)
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
      end
    end
  end
end
