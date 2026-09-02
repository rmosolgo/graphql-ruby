# frozen_string_literal: true

require "rdoc"
require "rdoc/generator/aliki"
require "cgi"
require "fileutils"
require "pathname"
require "yaml"

module RDoc
  module Generator
    class GraphQLRuby < Aliki
      ::RDoc::RDoc.add_generator self

      GUIDE_METADATA = YAML.safe_load(File.read(File.expand_path("../../docs/guide_metadata.yml", __dir__))).freeze
      PRODUCT_CALLOUTS = {
        "pro" => ["GraphQL-Pro", "https://graphql.pro"],
        "enterprise" => ["GraphQL-Enterprise", "https://graphql.pro/enterprise"],
      }.freeze

      def generate
        setup
        disambiguate_case_insensitive_paths
        super
        install_graphql_assets
      end

      def build_search_index
        entries = super + guide_search_entries
        entries = entries.filter_map { |entry| sanitize_search_entry(entry) }
        deduplicate_search_entries(entries)
      end

      private

      # GraphQL.html and Graphql.html collide on case-insensitive filesystems.
      # Keep the primary namespace at its expected URL and move the Rails
      # integration namespace root alongside its existing child pages.
      def disambiguate_case_insensitive_paths
        graphql_rails = @classes.find { |klass| klass.full_name == "Graphql" }
        graphql_rails&.define_singleton_method(:name_for_path) { "Graphql::index" }
      end

      # Darkfish extracts metadata directly from Markdown source, which cuts
      # link syntax at punctuation inside rdoc-ref targets. Render the snippet
      # first so page descriptions contain readable link labels.
      def excerpt(comment)
        document = if comment.respond_to?(:parse)
          comment.parse
        else
          parsed_comment = ::RDoc::Comment.new(comment.to_s)
          parsed_comment.format = @options.markup
          parsed_comment.parse
        end
        html = ::RDoc::Markup::ToHtmlSnippet.new(@options, 150).convert(document)
        CGI.unescapeHTML(html.gsub(/<[^>]+>/, " ")).gsub(/\s+/, " ").strip
      end

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
        sidebar_page_titles = page_titles
        Dir[output.join("**/*.html").to_s].each do |path|
          path = Pathname.new(path)
          normalize_malformed_html_images(path)
          normalize_heading_links(path)
          normalize_method_source_ids(path)
          normalize_root_relative_image_paths(path, output)
          normalize_guide_page_title(path, output, sidebar_page_titles)
          normalize_page_titles_in_sidebar(path, output, sidebar_page_titles)
          nest_guide_pages_in_sidebar(path, output, sidebar_page_titles)
          inject_product_callout(path, output)
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

      # RDoc parses inline HTML in Markdown headings as text around a nested
      # image element. Restore the original image attributes in the generated
      # HTML without changing the README source used by GitHub and RubyGems.
      def normalize_malformed_html_images(path)
        html = File.read(path)
        cleaned = html.gsub(/&lt;img src=“<img src="([^"]+)" \/>” height=“([^”]+)” alt=“([^”]+)”\/&gt;/) do
          %(<img src="#{Regexp.last_match(1)}" height="#{Regexp.last_match(2)}" alt="#{Regexp.last_match(3)}">)
        end
        File.write(path, cleaned) if cleaned != html
      end

      # Aliki wraps headings in permalink anchors while RDoc may link constants
      # inside the same heading. Remove the inner links to avoid invalid nested
      # anchors while keeping the heading permalink.
      def normalize_heading_links(path)
        html = File.read(path)
        cleaned = html.gsub(%r{(<h[1-6]\b[^>]*><a\b[^>]*>)(.*?)(</a></h[1-6]>)}m) do
          opening = Regexp.last_match(1)
          closing = Regexp.last_match(3)
          content = Regexp.last_match(2).gsub(%r{<a\b[^>]*>(.*?)</a>}m, "\\1")
          "#{opening}#{content}#{closing}"
        end
        File.write(path, cleaned) if cleaned != html
      end

      # Aliki uses only the method name for source IDs, so class and instance
      # methods with the same name receive duplicate IDs. Keep the first ID for
      # compatibility and make later source blocks unique.
      def normalize_method_source_ids(path)
        html = File.read(path)
        ids = Hash.new(0)
        cleaned = html.gsub(/(<div class="method-source-code" id=")([^"]+)(")/) do
          prefix, id, suffix = Regexp.last_match.captures
          ids[id] += 1
          ids[id] == 1 ? Regexp.last_match(0) : "#{prefix}#{id}-#{ids[id]}#{suffix}"
        end
        File.write(path, cleaned) if cleaned != html
      end

      # Guide Markdown uses site-root-relative image URLs. Make them relative
      # to each generated page so the documentation can also be viewed from a
      # local file:// URL.
      def normalize_root_relative_image_paths(path, output)
        html = File.read(path)
        relative_root = output.relative_path_from(path.dirname).to_s
        prefix = relative_root == "." ? "" : "#{relative_root}/"
        cleaned = html.gsub(/(<img\b[^>]*\bsrc=")\/([^"]+")/) do
          "#{Regexp.last_match(1)}#{prefix}#{Regexp.last_match(2)}"
        end
        File.write(path, cleaned) if cleaned != html
      end

      # RDoc puts every guide directly under one flat `guides` group. Rebuild
      # that group as `guides/<directory>/<page>` so pages such as
      # `authorization/overview` and `dataloader/overview` remain distinct.
      def nest_guide_pages_in_sidebar(path, output, page_titles)
        html = File.read(path)
        current_directory = path.relative_path_from(output).to_s[%r{\Aguides/([^/]+)/}, 1]
        cleaned = html.gsub(%r{(<nav\b.*?</nav>)}m) do |nav|
          nav.gsub(%r{(<li>\s*<details[^>]*>\s*<summary>.*?\bguides\b.*?</summary>\s*)<ul class="link-list">\s*(.*?)\s*</ul>\s*</details>\s*</li>}m) do
            section_match = Regexp.last_match
            prefix = section_match[1].sub(/\bguides\b/, "Guides")
            links = section_match[2]
            guide_links = links.scan(%r{<li>\s*<a href="([^"]*guides/(?:([^/]+)/)?([^/]+_md\.html))">\s*([^<]*?)\s*</a>\s*</li>}m).map do |href, directory, page, _label|
              page_path = ["guides", directory, page].compact.join("/")
              {
                href: href,
                directory: directory,
                name: page.sub(/_md\.html\z/, ""),
                page: page_titles[page_path] || page.sub(/_md\.html\z/, ""),
              }
            end
            next Regexp.last_match(0) if guide_links.empty?

            grouped = guide_links.group_by { |link| link[:directory] }
            nested = grouped.map do |directory, directory_links|
              if directory
                order = GUIDE_METADATA.dig("order", directory) || []
                directory_links.sort_by! { |link| [order.index(link[:name]) || order.length, link[:page]] }
                directory_label = directory.split("_").map(&:capitalize).join(" ").sub("Javascript", "JavaScript")
                entries = directory_links.map do |link|
                  <<~HTML
                    <li>
                      <a href="#{link[:href]}">
                        #{link[:page]}
                      </a>
                    </li>
                  HTML
                end.join
                <<~HTML
                  <li>
                    <details#{' open' if directory == current_directory}>
                      <summary>#{directory_label}</summary>
                      <ul class="link-list">
                        #{entries}
                      </ul>
                    </details>
                  </li>
                HTML
              else
                directory_links.map do |link|
                  <<~HTML
                    <li>
                      <a href="#{link[:href]}">
                        #{link[:page]}
                      </a>
                    </li>
                  HTML
                end.join
              end
            end.join
            "#{prefix}<ul class=\"link-list\">#{nested}</ul></details></li>"
          end
        end
        File.write(path, cleaned) if cleaned != html
      end

      def inject_product_callout(path, output)
        guide = path.relative_path_from(output).to_s[%r{\Aguides/(.+)_md\.html\z}, 1]
        return unless guide

        product = GUIDE_METADATA.fetch("products").find do |_name, patterns|
          patterns.any? { |pattern| File.fnmatch?(pattern, guide) }
        end&.first
        return unless product

        html = File.read(path)
        return if html.include?("<!-- graphql-ruby: product callout -->")

        name, url = PRODUCT_CALLOUTS.fetch(product)
        callout = <<~HTML
          <!-- graphql-ruby: product callout -->
          <aside class="graphql-product-callout">
            <strong>#{name} feature</strong>
            This feature ships with <a href="#{url}">#{name}</a> and is not included in GraphQL-Ruby OSS.
          </aside>
        HTML
        cleaned = html.sub(/(<main\b[^>]*>\s*)/, "\\1#{callout}")
        File.write(path, cleaned) if cleaned != html
      end

      def normalize_page_titles_in_sidebar(path, output, page_titles)
        return if page_titles.empty?

        html = File.read(path)
        cleaned = html.gsub(%r{(<nav\b.*?</nav>)}m) do |nav|
          nav.gsub(%r{(<a href=")([^"]+\.html)(">\s*)([^<]*?)(\s*)(</a>)}) do
            match = Regexp.last_match
            target = (path.dirname + match[2]).cleanpath
            title = page_titles[target.relative_path_from(output).to_s]
            title ? "#{match[1]}#{match[2]}#{match[3]}#{title}#{match[5]}#{match[6]}" : match[0]
          end
        end
        File.write(path, cleaned) if cleaned != html
      end

      def normalize_guide_page_title(path, output, page_titles)
        relative_path = path.relative_path_from(output).to_s
        return unless relative_path.start_with?("guides/") && (title = page_titles[relative_path])

        full_title = "#{title} - #{CGI.escapeHTML(@options.title)}"
        html = File.read(path)
        cleaned = html
          .sub(%r{<title>[^<]*</title>}, "<title>#{full_title}</title>")
          .sub(/(<meta property="og:title" content=")[^"]*(">)/, "\\1#{full_title}\\2")
          .sub(/(<meta name="twitter:title" content=")[^"]*(">)/, "\\1#{full_title}\\2")
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

          title = page_title(file)
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

      def page_titles
        @files.filter_map do |file|
          next unless file.text? && file.display?
          next unless file.path.start_with?("guides/") || file.path.start_with?("docs/") || file.full_name == @options.main_page

          [file.path, CGI.escapeHTML(page_title(file))]
        end.to_h
      end

      def page_title(file)
        return "README" if file.full_name == @options.main_page

        text = file.comment&.text.to_s
        source = file.file_name && File.file?(file.file_name) ? File.read(file.file_name) : text
        title = source[/^#\s+(.+)\s*$/, 1] || text[/^title:\s*["']?([^"'\n]+)["']?\s*$/i, 1]
        title = title&.gsub(/<img\b[^>]*>/i, "")&.strip
        title || file.page_name.to_s.sub(/_md\z/, "").tr("_", " ").split.map(&:capitalize).join(" ")
      end
    end
  end
end
