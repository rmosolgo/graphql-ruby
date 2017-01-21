# frozen_string_literal: true
module GraphQL
  module StaticValidation
    class FragmentsAreUsed
      include GraphQL::StaticValidation::Message::MessageHelper

      def validate(context)
        v = context.visitor
        used_fragments = []
        defined_fragments = []

        v[GraphQL::Language::Nodes::Document] << ->(node, parent) {
          defined_fragments = node.definitions
            .select { |defn| defn.is_a?(GraphQL::Language::Nodes::FragmentDefinition) }
            .map { |node| FragmentInstance.new(node: node) }
        }

        v[GraphQL::Language::Nodes::FragmentSpread] << ->(node, parent) {
          used_fragments << FragmentInstance.new(node: node)
          if defined_fragments.none? { |defn| defn.name == node.name }
            GraphQL::Language::Visitor::SKIP
          end
        }
        v[GraphQL::Language::Nodes::Document].leave << ->(node, parent) { add_errors(context, used_fragments, defined_fragments) }
      end

      private

      def add_errors(context, used_fragments, defined_fragments)
        undefined_fragments = find_difference(used_fragments, defined_fragments.map(&:name))
        undefined_fragments.each do |fragment|
          context.errors << message("Fragment #{fragment.name} was used, but not defined", fragment.node)
        end

        unused_fragments = find_difference(defined_fragments, used_fragments.map(&:name))
        unused_fragments.each do |fragment|
          context.errors << message("Fragment #{fragment.name} was defined, but not used", fragment.node)
        end
      end

      def find_difference(fragments, allowed_fragment_names)
        fragments.select {|f| f.name && !allowed_fragment_names.include?(f.name) }
      end

      class FragmentInstance
        attr_reader :name, :node
        def initialize(node:)
          @node = node
          @name = node.name
        end
      end
    end
  end
end
