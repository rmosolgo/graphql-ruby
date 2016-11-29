# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class DirectivesAreInValidLocations
      include GraphQL::StaticValidation::Message::MessageHelper
      include GraphQL::Language

      def validate(context)
        directives = context.schema.directives

        context.visitor[Nodes::Directive] << ->(node, parent) {
          validate_location(node, parent, directives, context)
        }
      end

      private

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

      def validate_location(ast_directive, ast_parent, directives, context)
        directive_defn = directives[ast_directive.name]
        case ast_parent
        when Nodes::OperationDefinition
          required_location = GraphQL::Directive.const_get(ast_parent.operation_type.upcase)
          assert_includes_location(directive_defn, ast_directive, required_location, context)
        when *SIMPLE_LOCATION_NODES
          required_location = SIMPLE_LOCATIONS[ast_parent.class]
          assert_includes_location(directive_defn, ast_directive, required_location, context)
        else
          context.errors << message("Directives can't be applied to #{ast_parent.class.name}s", ast_directive, context: context)
        end
      end

      def assert_includes_location(directive_defn, directive_ast, required_location, context)
        if !directive_defn.locations.include?(required_location)
          location_name = LOCATION_MESSAGE_NAMES[required_location]
          allowed_location_names = directive_defn.locations.map { |loc| LOCATION_MESSAGE_NAMES[loc] }
          context.errors << message("'@#{directive_defn.name}' can't be applied to #{location_name} (allowed: #{allowed_location_names.join(", ")})", directive_ast, context: context)
        end
      end
    end
  end
end
