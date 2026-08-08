# frozen_string_literal: true

require "rdoc"
require "rdoc/generator/aliki"

module RDoc
  module Generator
    class GraphQLRuby < Aliki
      ::RDoc::RDoc.add_generator self

      def build_search_index
        super + guide_search_entries
      end

      private

      def guide_search_entries
        @files.filter_map do |file|
          next unless file.text? && (file.path.start_with?("guides/") || file.path.start_with?("docs/"))
          next unless file.display?

          title = guide_title(file)
          snippet = file.search_snippet
          entry = {
            name: title,
            full_name: "Guide: #{title}",
            type: "guide",
            path: file.path,
          }
          entry[:snippet] = snippet unless snippet.empty?
          entry
        end
      end

      def guide_title(file)
        text = file.comment&.text.to_s
        title = text[/^title:\s*["']?([^"'\n]+)["']?\s*$/i, 1]
        title&.strip || file.page_name.to_s.sub(/_md\z/, "").tr("_", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
