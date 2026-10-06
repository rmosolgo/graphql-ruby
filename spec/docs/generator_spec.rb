# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/generator"

describe RDoc::Generator::GraphQLRuby do
  it "uses distinct paths for GraphQL and Graphql on case-insensitive filesystems" do
    graphql = RDoc::NormalModule.new("GraphQL")
    graphql_rails = RDoc::NormalModule.new("Graphql")
    generator = RDoc::Generator::GraphQLRuby.allocate
    generator.instance_variable_set(:@classes, [graphql, graphql_rails])

    generator.send(:disambiguate_case_insensitive_paths)

    _(graphql.path).must_equal "GraphQL.html"
    _(graphql_rails.path).must_equal "Graphql/index.html"
  end

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
      javascript = output.join("guides/javascript_client/overview_md.html")
      authorization.dirname.mkpath
      dataloader.dirname.mkpath
      javascript.dirname.mkpath
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
                  <a href="../../guides/authorization/authorization_md.html">
                    authorization
                  </a>
                </li>
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
                <li>
                  <a href="../../guides/javascript_client/overview_md.html">
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
        "guides/authorization/authorization_md.html" => "Authorization",
        "guides/authorization/overview_md.html" => "Authorization Overview",
        "guides/dataloader/overview_md.html" => "Dataloader Overview",
        "guides/javascript_client/overview_md.html" => "JavaScript Client Overview",
        "docs/maintenance_md.html" => "Documentation maintenance",
        "readme_md.html" => "README",
      }
      generator.send(:normalize_page_titles_in_sidebar, authorization, output, page_titles)
      generator.send(:nest_guide_pages_in_sidebar, authorization, output, page_titles)

      html = File.read(authorization)
      _(html).must_include('<summary>Authorization</summary>')
      _(html).must_include('<summary>Dataloader</summary>')
      _(html).must_include('<summary>JavaScript Client</summary>')
      _(html).must_include('<summary>Guides</summary>')
      _(html).must_match(/<details open>\s*<summary>Authorization<\/summary>/)
      _(html).must_include("Authorization Overview")
      _(html.index("authorization/overview_md.html")).must_be :<, html.index("authorization/authorization_md.html")
      _(html).must_include("Dataloader Overview")
      _(html).must_include("Documentation maintenance")
      _(html).must_match(/>\s*README\s*</)
      _(html).must_include('href="../../guides/authorization/overview_md.html"')
      _(html).must_include('href="../../guides/dataloader/overview_md.html"')
    end
  end

  it "uses guide headings for browser and social titles" do
    Dir.mktmpdir("graphql-docs") do |directory|
      output = Pathname.new(directory)
      path = output.join("guides/changesets/overview_md.html")
      path.dirname.mkpath
      File.write(path, <<~HTML)
        <title>overview - GraphQL Ruby API Documentation</title>
        <meta property="og:title" content="overview - GraphQL Ruby API Documentation">
        <meta name="twitter:title" content="overview - GraphQL Ruby API Documentation">
      HTML

      generator = RDoc::Generator::GraphQLRuby.allocate
      generator.instance_variable_set(:@options, Struct.new(:title).new("GraphQL Ruby API Documentation"))
      generator.send(:normalize_guide_page_title, path, output, {
        "guides/changesets/overview_md.html" => "API Versioning for GraphQL-Ruby",
      })

      html = File.read(path)
      _(html.scan("API Versioning for GraphQL-Ruby - GraphQL Ruby API Documentation").length).must_equal 3
      _(html).wont_include("overview - GraphQL Ruby API Documentation")
    end
  end

  it "renders Markdown links as plain text in metadata excerpts" do
    comment = RDoc::Comment.new("A result from [Schema.execute](rdoc-ref:GraphQL::Schema.execute).")
    comment.format = "markdown"
    generator = RDoc::Generator::GraphQLRuby.allocate
    generator.instance_variable_set(:@options, RDoc::Options.new)

    excerpt = generator.send(:excerpt, comment)

    _(excerpt).must_equal("A result from Schema.execute.")
  end

  it "removes nested links from heading permalinks" do
    Dir.mktmpdir("graphql-docs") do |directory|
      path = Pathname.new(directory).join("GraphQL/Schema.html")
      path.dirname.mkpath
      File.write(path, '<h2 id="root-types"><a href="#root-types">Root <a href="Types.html"><code>Types</code></a></a></h2>')

      RDoc::Generator::GraphQLRuby.allocate.send(:normalize_heading_links, path)

      _(File.read(path)).must_equal '<h2 id="root-types"><a href="#root-types">Root <code>Types</code></a></h2>'
    end
  end

  it "makes duplicate method source IDs unique" do
    Dir.mktmpdir("graphql-docs") do |directory|
      path = Pathname.new(directory).join("GraphQL/Parser.html")
      path.dirname.mkpath
      File.write(path, '<div class="method-source-code" id="parse-source"></div><div class="method-source-code" id="parse-source"></div>')

      RDoc::Generator::GraphQLRuby.allocate.send(:normalize_method_source_ids, path)

      _(File.read(path)).must_equal '<div class="method-source-code" id="parse-source"></div><div class="method-source-code" id="parse-source-2"></div>'
    end
  end

  it "adds GraphQL-Pro and GraphQL-Enterprise guide callouts" do
    Dir.mktmpdir("graphql-docs") do |directory|
      output = Pathname.new(directory)
      pro = output.join("guides/defer/overview_md.html")
      enterprise = output.join("guides/changesets/overview_md.html")
      oss = output.join("guides/authorization/overview_md.html")
      [pro, enterprise, oss].each do |path|
        path.dirname.mkpath
        File.write(path, '<main role="main"><h1>Overview</h1></main>')
      end

      generator = RDoc::Generator::GraphQLRuby.allocate
      generator.send(:inject_product_callout, pro, output)
      generator.send(:inject_product_callout, enterprise, output)
      generator.send(:inject_product_callout, oss, output)

      _(File.read(pro)).must_include("GraphQL-Pro feature")
      _(File.read(pro)).must_include("https://graphql.pro")
      _(File.read(enterprise)).must_include("GraphQL-Enterprise feature")
      _(File.read(enterprise)).must_include("https://graphql.pro/enterprise")
      _(File.read(oss)).wont_include("graphql-product-callout")
    end
  end

  it "defines an order for every nested guide" do
    expected = Dir[File.expand_path("../../guides/*/*.md", __dir__)]
      .reject { |path| path.include?("/guides/yardoc/") }
      .map { |path| path[%r{/guides/(.+)\.md\z}, 1] }
    actual = RDoc::Generator::GraphQLRuby::GUIDE_METADATA.fetch("order").flat_map do |directory, guides|
      guides.map { |guide| "#{directory}/#{guide}" }
    end

    _(actual.sort).must_equal expected.sort
  end
end
