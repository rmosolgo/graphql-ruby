module GraphQL
  class Query
    class SerialExecution
      class ExecutionContext
        attr_reader :query, :schema, :strategy

        def initialize(query, strategy)
          @query = query
          @schema = query.schema
          @strategy = strategy
          @warden = query.warden
        end

        def get_type(type_name)
          @warden.get_type(type_name)
        end

        def get_fragment(name)
          @query.fragments[name]
        end

        def get_field(type, irep_node)
          # fall back for dynamic fields (eg __typename)
          irep_node.definitions[type] || @warden.get_field(type, irep_node.definition_name) || raise("No field found on #{type.name} for '#{irep_node.definition_name}' (#{irep_node.ast_node.name})")
        end

        def possible_types(type)
          @warden.possible_types(type)
        end

        def add_error(err)
          @query.context.errors << err
        end

        def handle_invalid_null(err)
          @schema.invalid_null(err, @query.context)
        end
      end
    end
  end
end
