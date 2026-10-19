# frozen_string_literal: true

require "json"
require "pathname"

module GraphQLDocs
  class LegacyAnchors
    def self.install(root:, search_index: nil)
      new(root, search_index: search_index).install
    end

    def initialize(root, search_index: nil)
      @root = Pathname.new(root).expand_path
      @search_index = search_index || @root.join("js/search_data.js")
    end

    def install
      entries.each do |entry|
        next unless ["instance_method", "class_method"].include?(entry.fetch("type"))

        path, current_fragment = entry.fetch("path").split("#", 2)
        next unless current_fragment

        page = @root.join(path)
        next unless page.file?

        legacy_fragment = legacy_fragment(entry)
        html = File.read(page)
        current_anchor = html.match(anchor_pattern(current_fragment))
        next unless current_anchor
        next if html.match?(anchor_pattern(legacy_fragment))

        html.insert(current_anchor.begin(0), %(<span id="#{legacy_fragment}" class="legacy-anchor"></span>\n))
        File.write(page, html)
      end
    end

    private

    def entries
      data = File.read(@search_index).strip.delete_prefix("var search_data = ").delete_suffix(";")
      JSON.parse(data).fetch("index")
    end

    def legacy_fragment(entry)
      "#{entry.fetch("name")}-#{entry.fetch("type")}"
    end

    def anchor_pattern(fragment)
      %r{<[A-Za-z][^>]*\sid\s*=\s*(["'])#{Regexp.escape(fragment)}\1[^>]*>}
    end
  end
end
