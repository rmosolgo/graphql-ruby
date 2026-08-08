# frozen_string_literal: true

require "json"
require "pathname"
require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/legacy"
require_relative "../../tool/docs/redirects"

describe GraphQLDocs::LegacyAnchors do
  it "adds legacy method anchors from the RDoc index" do
    Dir.mktmpdir("graphql-docs") do |directory|
      root = Pathname.new(directory)
      FileUtils.mkdir_p(root.join("js"))
      File.write(root.join("js/search_data.js"), <<~JS)
        var search_data = {"index":[{"full_name":"GraphQL::Schema#execute","type":"instance_method","path":"GraphQL/Schema.html#method-i-execute"}]};
      JS
      FileUtils.mkdir_p(root.join("GraphQL"))
      File.write(root.join("GraphQL/Schema.html"), '<span id="method-i-execute" class="legacy-anchor"></span>')
      GraphQLDocs::LegacyAnchors.install(root: root)
      _(File.read(root.join("GraphQL/Schema.html"))).must_include('id="execute-instance_method"')
    end
  end
end

describe GraphQLDocs::Redirects do
  it "writes clean and html redirect entry points" do
    Dir.mktmpdir("graphql-docs") do |directory|
      root = Pathname.new(directory)
      output = root.join("site")
      FileUtils.mkdir_p(root.join("docs"))
      File.write(root.join("docs/redirects.yml"), <<~YAML)
        redirects:
          - old_path: /queries/executing_queries
            destination:
              kind: page
              value: guides/queries/executing_queries.md
      YAML
      GraphQLDocs::Redirects.generate(root: root, output: output)
      index = output.join("queries/executing_queries/index.html")
      html = output.join("queries/executing_queries.html")
      _(index).must_be :file?
      _(html).must_be :file?
      _(File.read(index)).must_include("guides/queries/executing_queries_md.html")
      _(File.read(index)).must_include("window.location.replace")
    end
  end
end
