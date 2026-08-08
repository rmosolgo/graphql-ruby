# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/generator"

describe RDoc::Generator::GraphQLRuby do
  it "deduplicates API entries while retaining guide entries" do
    generator = RDoc::Generator::GraphQLRuby.allocate
    entries = generator.send(:deduplicate_search_entries, [
      { type: "class", full_name: "GraphQL::Schema" },
      { type: "class", full_name: "GraphQL::Schema" },
      { type: "guide", full_name: "Guide: Getting Started" },
    ])

    _(entries.map { |entry| entry[:full_name] }).must_equal ["GraphQL::Schema", "Guide: Getting Started"]
  end

  it "preserves API visibility text and escapes search snippets" do
    generator = RDoc::Generator::GraphQLRuby.allocate

    private_entry = generator.send(:sanitize_search_entry, {
      type: "class",
      full_name: "GraphQL::Internal",
      snippet: "<p><strong>API:</strong> private</p>",
    })
    _(private_entry[:snippet]).must_equal "API: private"

    entry = generator.send(:sanitize_search_entry, {
      type: "class",
      full_name: "GraphQL::Schema",
      "snippet" => "<p>See [Schema](rdoc-ref:GraphQL::Schema) <script>alert(1)</script></p>",
    })
    _([entry[:snippet], entry["snippet"]].compact.first).must_equal "See Schema alert(1)"
  end

  it "removes unresolved rdoc-ref pseudo-URLs while preserving labels" do
    Dir.mktmpdir("graphql-docs") do |directory|
      path = File.join(directory, "index.html")
      File.write(path, '<p>[Schema](rdoc-ref:GraphQL::Schema)</p><code>rdoc-ref:Query#initialize</code>')

      generator = RDoc::Generator::GraphQLRuby.allocate
      generator.send(:remove_unresolved_rdoc_refs, Pathname.new(path))

      html = File.read(path)
      _(html).must_include("Schema")
      _(html).must_include("Query#initialize")
      _(html).wont_include("rdoc-ref:")
    end
  end

  it "restores attributes for inline HTML images in generated headings" do
    Dir.mktmpdir("graphql-docs") do |directory|
      path = File.join(directory, "readme_md.html")
      File.write(path, '<h1>graphql &lt;img src=“<img src="logo.png" />” height=“40” alt=“graphql-ruby”/&gt;</h1>')

      generator = RDoc::Generator::GraphQLRuby.allocate
      generator.send(:normalize_malformed_html_images, Pathname.new(path))

      html = File.read(path)
      _(html).must_include('<img src="logo.png" height="40" alt="graphql-ruby">')
      _(html).wont_include('&lt;img src=')
    end
  end

  it "makes root-relative image paths local-file friendly" do
    Dir.mktmpdir("graphql-docs") do |directory|
      output = Pathname.new(directory)
      path = output.join("guides/object_cache/overview_md.html")
      path.dirname.mkpath
      File.write(path, '<p><img src="/object_cache/query-without-cache.png"></p>')

      generator = RDoc::Generator::GraphQLRuby.allocate
      generator.send(:normalize_root_relative_image_paths, path, output)

      _(File.read(path)).must_include('<img src="../../object_cache/query-without-cache.png">')
    end
  end

  it "nests guide directories in the sidebar" do
    Dir.mktmpdir("graphql-docs") do |directory|
      output = Pathname.new(directory)
      authorization = output.join("guides/authorization/overview_md.html")
      dataloader = output.join("guides/dataloader/overview_md.html")
      authorization.dirname.mkpath
      dataloader.dirname.mkpath
      sidebar = <<~HTML
        <nav>
          <a href="../../docs/maintenance_md.html">
            maintenance
          </a>
          <a href="../../readme_md.html">
            readme
          </a>
          <li>
            <details open>
              <summary>guides</summary>
              <ul class="link-list">
                <li>
                  <a href="../../guides/authorization/overview_md.html">
                    overview
                  </a>
                </li>
                <li>
                  <a href="../../guides/dataloader/overview_md.html">
                    overview
                  </a>
                </li>
              </ul>
            </details>
          </li>
        </nav>
      HTML
      File.write(authorization, sidebar)

      generator = RDoc::Generator::GraphQLRuby.allocate
      page_titles = {
        "guides/authorization/overview_md.html" => "Authorization Overview",
        "guides/dataloader/overview_md.html" => "Dataloader Overview",
        "docs/maintenance_md.html" => "Documentation maintenance",
        "readme_md.html" => "README",
      }
      generator.send(:normalize_page_titles_in_sidebar, authorization, output, page_titles)
      generator.send(:nest_guide_pages_in_sidebar, authorization, output, page_titles)

      html = File.read(authorization)
      _(html).must_include('<summary>Authorization</summary>')
      _(html).must_include('<summary>Dataloader</summary>')
      _(html).must_include('<summary>Guides</summary>')
      _(html).must_match(/<details open>\s*<summary>Authorization<\/summary>/)
      _(html).must_include("Authorization Overview")
      _(html).must_include("Dataloader Overview")
      _(html).must_include("Documentation maintenance")
      _(html).must_match(/>\s*README\s*</)
      _(html).must_include('href="../../guides/authorization/overview_md.html"')
      _(html).must_include('href="../../guides/dataloader/overview_md.html"')
    end
  end
end
