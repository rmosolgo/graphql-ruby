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
end
