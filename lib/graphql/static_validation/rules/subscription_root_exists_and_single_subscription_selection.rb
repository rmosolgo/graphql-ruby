# frozen_string_literal: true
module GraphQL
  module StaticValidation
    module SubscriptionRootExistsAndSingleSubscriptionSelection
      def on_operation_definition(node, parent)
        if node.operation_type == "subscription"
          if context.types.subscription_root.nil?
            add_error(GraphQL::StaticValidation::SubscriptionRootExistsError.new(
              'Schema is not configured for subscriptions',
              nodes: node
            ))
          else
            root_fields = subscription_root_fields(node)
            if root_fields.map { |field| field.alias || field.name }.uniq.size != 1
              add_error(GraphQL::StaticValidation::NotSingleSubscriptionError.new(
                'A subscription operation may only have one selection',
                nodes: node,
              ))
            elsif root_fields.any? { |field| field.name.start_with?("__") }
              add_error(GraphQL::StaticValidation::NotSingleSubscriptionError.new(
                'A subscription operation may not select an introspection field',
                nodes: node,
              ))
            end
            super
          end
        else
          super
        end
      end

      private

      def subscription_root_fields(node)
        root_type = context.types.subscription_root
        fields = []
        selections = node.selections.dup
        visited_fragments = {}

        while (selection = selections.pop)
          case selection
          when GraphQL::Language::Nodes::Field
            fields << selection
          when GraphQL::Language::Nodes::FragmentSpread
            next if visited_fragments[selection.name]
            visited_fragments[selection.name] = true
            fragment = context.fragments[selection.name]
            selections << fragment if fragment
          when GraphQL::Language::Nodes::InlineFragment, GraphQL::Language::Nodes::FragmentDefinition
            fragment_type = selection.type ? @types.type(selection.type.name) : root_type
            if fragment_type && fragment_type.kind.composite? && @types.possible_types(fragment_type).include?(root_type)
              selections.concat(selection.selections)
            end
          end
        end

        fields
      end
    end
  end
end
