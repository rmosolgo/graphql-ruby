class GraphQL::StaticValidation::FragmentsAreUsed
  include GraphQL::StaticValidation::Message::MessageHelper

  def validate(context)
    v = context.visitor
    used_fragments = []
    defined_fragments = []
    v[GraphQL::Language::Nodes::FragmentSpread] << -> (node, parent) { used_fragments <<  node }
    v[GraphQL::Language::Nodes::FragmentDefinition] << -> (node, parent) { defined_fragments << node}
    v[GraphQL::Language::Nodes::Document].leave << -> (node, parent) { add_errors(context.errors, used_fragments, defined_fragments) }
  end

  private

  def add_errors(errors, used_fragments, defined_fragments)
    undefined_fragments = find_difference(used_fragments, defined_fragments.map(&:name))
    undefined_fragments.each do |fragment|
      errors << message("Fragment #{fragment.name} was used, but not defined", fragment)
    end

    unused_fragments = find_difference(defined_fragments, used_fragments.map(&:name))
    unused_fragments.each do |fragment|
      errors << message("Fragment #{fragment.name} was defined, but not used", fragment)
    end
  end

  def find_difference(fragments, allowed_fragment_names)
    fragments.select {|f| !allowed_fragment_names.include?(f.name) }
  end
end
