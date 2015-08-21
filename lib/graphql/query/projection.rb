module GraphQL::Query::Projection
  class OperationProjector
    attr_reader :definition, :query, :root
    def initialize(definition, query)
      @query = query
      @definition = definition
      @root = if definition.operation_type == "query"
        query.schema.query
      elsif definition.operation_type == "mutation"
        query.schema.mutation
      end
    end

    def result
      SelectionProjector.new(root, definition.selections, query).result
    end
  end

  class SelectionProjector
    PROJECTION_STRATEGIES = {
      GraphQL::Language::Nodes::Field =>          :FieldProjectionStrategy,
      GraphQL::Language::Nodes::FragmentSpread => :FragmentSpreadProjectionStrategy,
      GraphQL::Language::Nodes::InlineFragment => :InlineFragmentProjectionStrategy,
    }

    attr_reader :types, :selections, :query
    def initialize(type, selections, query)
      base_type = type.kind.unwrap(type)
      @types = if base_type.kind.resolves?
        base_type.possible_types
      else
        [base_type]
      end
      @selections = selections
      @query = query
    end

    def result
      types.reduce({}) do |types_memo, type|
        types_memo[type.name] = selections.reduce({}) do |memo, ast_field|
          chain = GraphQL::Query::DirectiveChain.new(ast_field, query) {
            strategy_class = GraphQL::Query::Projection.const_get(PROJECTION_STRATEGIES[ast_field.class])
            strategy = strategy_class.new(type, ast_field, query)
            strategy.result
          }
          memo.merge(chain.result)
        end
        types_memo
      end
    end
  end

  class FieldProjectionStrategy
    attr_reader :result
    def initialize(type, ast_field, query)
      field_defn = query.schema.get_field(type, ast_field.name)
      if field_defn.nil? # eg, a fragment on an interface
        projection = nil
      else
        child_projector = SelectionProjector.new(field_defn.type, ast_field.selections, query)
        child_projections = child_projector.result
        arguments = GraphQL::Query::Arguments.new(ast_field.arguments, field_defn.arguments, query.variables).to_h
        projection = query.context.projecting(child_projections) do
          field_defn.project(type, arguments, query.context)
        end
        field_label = ast_field.alias || ast_field.name
        query.context.projection_map[ast_field] = projection
      end
      @result = { field_label => projection }
    end
  end

  class FragmentSpreadProjectionStrategy
    attr_reader :result
    def initialize(type, ast_fragment_spread, query)
      fragment_def = query.fragments[ast_fragment_spread.name]
      selections = fragment_def.selections
      resolver = GraphQL::Query::Projection::SelectionProjector.new(type, selections, query)
      @result = resolver.result[type.name]
    end
  end

  class InlineFragmentProjectionStrategy
    attr_reader :result
    def initialize(type, ast_inline_fragment, query)
      selections = ast_inline_fragment.selections
      resolver = GraphQL::Query::Projection::SelectionProjector.new(type, selections, query)
      @result = resolver.result[type.name]
    end
  end
end
