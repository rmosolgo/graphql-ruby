# frozen_string_literal: true
module GraphQL
  module Language
    module DefinitionSlice
      extend self

      def slice(document, name)
        definitions = {}
        document.definitions.each { |d| definitions[d.name] = d }
        names = find_definition_dependencies(definitions, name)
        definitions = document.definitions.select { |d| names.include?(d.name) }
        Nodes::Document.new(definitions: definitions)
      end

      private

      def find_definition_dependencies(definitions, name)
        names = Set.new([name])
        visitor = Visitor.new(definitions[name])
        visitor[Nodes::FragmentSpread] << ->(node, parent) {
          if fragment = definitions[node.name]
            names.merge(find_definition_dependencies(definitions, fragment.name))
          end
        }
        visitor.visit
        names
      end
    end
  end
end
