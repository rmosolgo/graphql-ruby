module GraphQL
  module StaticAnalysis
    class TypeCheck
      module ValidDirectives
        include GraphQL::Language

        module_function
        # @return [Array<AnalysisError>] Any errors because of this node's location
        def location_errors(directive_defn, ast_directive_node, ast_parent_node)
          errors = []
          required_location = case ast_parent_node
          when Nodes::OperationDefinition
            GraphQL::Directive.const_get(ast_parent_node.operation_type.upcase)
          when *SIMPLE_LOCATION_NODES
            SIMPLE_LOCATIONS[ast_parent_node.class]
          else
            nil
          end

          if required_location.nil?
            node_type = ast_parent_node.class.name.split("::").last
            errors << AnalysisError.new(
              %|Directives can't be applied to #{node_type}s|,
              nodes: [ast_directive_node]
            )
          elsif !directive_defn.locations.include?(required_location)
            location_name = LOCATION_MESSAGE_NAMES[required_location]
            allowed_location_names = directive_defn.locations.map { |loc| LOCATION_MESSAGE_NAMES[loc] }
            errors << AnalysisError.new(
              %|Directive "@#{directive_defn.name}" can't be applied to #{location_name} (allowed: #{allowed_location_names.join(", ")})|,
              nodes: [ast_directive_node]
            )
          end

          errors
        end


        LOCATION_MESSAGE_NAMES = {
          GraphQL::Directive::QUERY =>               "queries",
          GraphQL::Directive::MUTATION =>            "mutations",
          GraphQL::Directive::SUBSCRIPTION =>        "subscriptions",
          GraphQL::Directive::FIELD =>               "fields",
          GraphQL::Directive::FRAGMENT_DEFINITION => "fragment definitions",
          GraphQL::Directive::FRAGMENT_SPREAD =>     "fragment spreads",
          GraphQL::Directive::INLINE_FRAGMENT =>     "inline fragments",
        }

        SIMPLE_LOCATIONS = {
          Nodes::Field =>               GraphQL::Directive::FIELD,
          Nodes::InlineFragment =>      GraphQL::Directive::INLINE_FRAGMENT,
          Nodes::FragmentSpread =>      GraphQL::Directive::FRAGMENT_SPREAD,
          Nodes::FragmentDefinition =>  GraphQL::Directive::FRAGMENT_DEFINITION,
        }

        SIMPLE_LOCATION_NODES = SIMPLE_LOCATIONS.keys
      end
    end
  end
end
