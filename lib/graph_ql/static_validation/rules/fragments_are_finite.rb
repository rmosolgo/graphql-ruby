class GraphQL::StaticValidation::FragmentsAreFinite
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)

    context.visitor[GraphQL::Nodes::Document].leave << -> (node, parent) {
      context.fragments.each do |name, fragment_def|
        if has_nested_spread(fragment_def, [], context)
          context.errors << message("Fragment #{fragment_def.name} contains an infinite loop", fragment_def)
        end
      end
    }
  end

  private

  def has_nested_spread(fragment_def, parent_fragment_names, context)
    nested_spreads = fragment_def.selections
      .select {|f| f.is_a?(GraphQL::Nodes::FragmentSpread)}

    nested_spreads.any? do |spread|
      nested_def = context.fragments[spread.name]
      parent_fragment_names.include?(spread.name) || has_nested_spread(nested_def, parent_fragment_names + [fragment_def.name], context)
    end
  end
end
