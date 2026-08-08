# frozen_string_literal: true

require "rdoc"
require "rdoc/generator/aliki"
require "cgi"
require "fileutils"
require "pathname"

module RDoc
  module Generator
    class GraphQLRuby < Aliki
      ::RDoc::RDoc.add_generator self

      def generate
        super
        install_graphql_assets
      end

      def build_search_index
        entries = super + guide_search_entries
        entries = entries.filter_map { |entry| sanitize_search_entry(entry) }
        deduplicate_search_entries(entries)
      end

      private

      def deduplicate_search_entries(entries)
        entries.uniq { |entry| [entry[:type] || entry["type"], entry[:full_name] || entry["full_name"]] }
      end

      def sanitize_search_entry(entry)
        snippet = entry[:snippet] || entry["snippet"]
        return entry unless snippet

        sanitized = snippet
          .gsub(/\[([^\]]+)\]\(rdoc-ref:[^)]+\)/, "\\1")
          .gsub(/rdoc-ref:[A-Za-z][A-Za-z0-9_:#.?!-]*/, "")
          .gsub(/<[^>]+>/, " ")
          .then { |text| CGI.unescapeHTML(text) }
          .gsub(/\s+/, " ")
          .strip
        key = entry.key?(:snippet) ? :snippet : "snippet"
        entry.merge(key => CGI.escapeHTML(sanitized))
      end

      def install_graphql_assets
        output = Pathname.new(@options.op_dir.to_s)
        asset_root = Pathname.new(__dir__).join("assets")
        FileUtils.mkdir_p(output.join("js"))
        FileUtils.mkdir_p(output.join("css"))
        FileUtils.cp(asset_root.join("graphql_highlighter.js"), output.join("js/graphql_highlighter.js"))
        FileUtils.cp(asset_root.join("graphql_highlighter.css"), output.join("css/graphql_highlighter.css"))
        Dir[output.join("**/*.html").to_s].each do |path|
          path = Pathname.new(path)
          remove_source_links(path)
          remove_unresolved_rdoc_refs(path)
          inject_graphql_assets(path, output)
        end
      end

      def remove_source_links(path)
        html = File.read(path)
        cleaned = html.gsub(/<a href="[^"]*\/lib\/[^\"]*">([^<]+)<\/a>/, '<code>\\1</code>')
        File.write(path, cleaned) if cleaned != html
      end

      # RDoc renders an unresolved `rdoc-ref:` as plain text. This is especially
      # common in metadata and code examples, where the reference isn't a
      # cross-reference in the first place. Keep the visible label, but never
      # publish an unusable pseudo-URL.
      def remove_unresolved_rdoc_refs(path)
        html = File.read(path)
        cleaned = html.gsub(/\[([^\]]+)\]\(rdoc-ref:[^)]+\)/, '\\1')
        cleaned = cleaned.gsub(/rdoc-ref:([A-Za-z][A-Za-z0-9_:#.?!-]*)/, '\\1')
        File.write(path, cleaned) if cleaned != html
      end

      def inject_graphql_assets(path, output)
        html = File.read(path)
        return if html.include?("<!-- graphql-ruby: graphql highlighter -->")

        relative_root = output.relative_path_from(path.dirname).to_s
        prefix = relative_root == "." ? "" : "#{relative_root}/"
        marker = <<~HTML
          <!-- graphql-ruby: graphql highlighter -->
          <link rel="stylesheet" href="#{prefix}css/graphql_highlighter.css">
          <script src="#{prefix}js/graphql_highlighter.js" defer></script>
        HTML
        html = html.sub(/<body\b/, "#{marker}<body")
        File.write(path, html)
      end

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
        source = file.file_name && File.file?(file.file_name) ? File.read(file.file_name) : text
        title = source[/^#\s+(.+)\s*$/, 1] || text[/^title:\s*["']?([^"'\n]+)["']?\s*$/i, 1]
        title&.strip || file.page_name.to_s.sub(/_md\z/, "").tr("_", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
