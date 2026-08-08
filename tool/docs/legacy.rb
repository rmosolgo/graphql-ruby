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
        next unless %w[instance_method class_method].include?(entry.fetch("type"))

        path, current_fragment = entry.fetch("path").split("#", 2)
        next unless current_fragment

        page = @root.join(path)
        next unless page.file?

        legacy_fragment = legacy_fragment(entry)
        html = File.read(page)
        anchors = []
        unless html.include?(%(<span id="#{current_fragment}"))
          anchors << %(<span id="#{current_fragment}" class="legacy-anchor"></span>)
        end
        unless html.include?(%(<span id="#{legacy_fragment}"))
          anchors << %(<span id="#{legacy_fragment}" class="legacy-anchor"></span>)
        end
        next if anchors.empty?

        insertion = "#{anchors.join("\n")}\n"
        if html.include?(%(<span id="#{current_fragment}"))
          html = html.sub(%r{(<span id="#{Regexp.escape(current_fragment)}")}, "#{insertion}\\1")
        else
          html = html.sub(%r{</main>}, "#{insertion}</main>")
        end
        File.write(page, html)
      end
    end

    private

    def entries
      data = File.read(@search_index).strip.delete_prefix("var search_data = ").delete_suffix(";")
      JSON.parse(data).fetch("index")
    end

    def legacy_fragment(entry)
      name = entry.fetch("full_name")
      method_name = entry.fetch("type") == "instance_method" ? name.split("#", 2).last : name.split(".").last
      "#{method_name}-#{entry.fetch("type")}"
    end
  end
end
