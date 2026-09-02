# frozen_string_literal: true

require "json"
require "pathname"
require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/legacy"
require_relative "../../tool/docs/redirects"

describe GraphQLDocs::LegacyAnchors do
  it "adds legacy method anchors beside RDoc method anchors" do
    Dir.mktmpdir("graphql-docs") do |directory|
      root = Pathname.new(directory)
      FileUtils.mkdir_p(root.join("js"))
      File.write(root.join("js/search_data.js"), <<~JS)
        var search_data = {"index":[
          {"name":"execute","full_name":"GraphQL::Schema::execute","type":"class_method","path":"GraphQL/Schema.html#method-c-execute"},
          {"name":"execute","full_name":"GraphQL::Schema#execute","type":"instance_method","path":"GraphQL/Schema.html#method-i-execute"}
        ]};
      JS
      FileUtils.mkdir_p(root.join("GraphQL"))
      File.write(root.join("GraphQL/Schema.html"), <<~HTML)
        <main>
        <div id="method-c-execute" class="method-detail anchor-link"></div>
        <div class="method-detail anchor-link" id="method-i-execute"></div>
        </main>
      HTML

      2.times { GraphQLDocs::LegacyAnchors.install(root: root) }

      generated = File.read(root.join("GraphQL/Schema.html"))
      _(generated).must_match(/<span id="execute-class_method" class="legacy-anchor"><\/span>\n<div id="method-c-execute"/)
      _(generated).must_match(/<span id="execute-instance_method" class="legacy-anchor"><\/span>\n<div class="method-detail anchor-link" id="method-i-execute"/)
      _(generated).wont_include('id="GraphQL::Schema::execute-class_method"')
      ["method-c-execute", "method-i-execute", "execute-class_method", "execute-instance_method"].each do |anchor|
        _(generated.scan(%(id="#{anchor}")).size).must_equal(1)
      end
    end
  end
end

describe GraphQLDocs::Redirects do
  it "writes clean and html redirect entry points" do
    Dir.mktmpdir("graphql-docs") do |directory|
      root = Pathname.new(directory)
      output = root.join("site")
      FileUtils.mkdir_p(root.join("docs"))
      FileUtils.mkdir_p(output.join("js"))
      File.write(output.join("js/search_data.js"), <<~JS)
        var search_data = {"index":[{"full_name":"GraphQL::Schema::execute","type":"class_method","path":"GraphQL/Schema.html#method-c-execute"}]};
      JS
      File.write(root.join("docs/redirects.yml"), <<~YAML)
        redirects:
          - old_path: /queries/executing_queries
            destination:
              kind: page
              value: guides/queries/executing_queries.md
          - old_path: /queries/executing_queries_api
            destination:
              kind: rdoc_ref
              value: GraphQL::Schema.execute
      YAML
      GraphQLDocs::Redirects.generate(root: root, output: output)
      index = output.join("queries/executing_queries/index.html")
      html = output.join("queries/executing_queries.html")
      _(index).must_be :file?
      _(html).must_be :file?
      _(File.read(index)).must_include("guides/queries/executing_queries_md.html")
      _(File.read(index)).must_include('window.location.replace("/guides/queries/executing_queries_md.html" + (window.location.hash || ""))')
      api_redirect = File.read(output.join("queries/executing_queries_api/index.html"))
      _(api_redirect).must_include('window.location.replace("/GraphQL/Schema.html" + (window.location.hash || "#method-c-execute"))')
    end
  end
end
