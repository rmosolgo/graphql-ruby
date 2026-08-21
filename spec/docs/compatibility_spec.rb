# frozen_string_literal: true

require "json"
require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/compatibility"

describe GraphQLDocs::Compatibility do
  it "compares the RDoc index with the committed YARD API baseline" do
    Dir.mktmpdir("graphql-docs") do |directory|
      File.write(File.join(directory, "GraphQL.html"), '<h1 id="method-c-execute">execute</h1>')
      index_path = File.join(directory, "search_data.js")
      File.write(index_path, <<~JS)
        var search_data = {"index":[
          {"full_name":"GraphQL::Schema","type":"class","path":"GraphQL.html","snippet":"Schema"},
          {"full_name":"GraphQL::Schema::execute","type":"class_method","path":"GraphQL.html#method-c-execute","snippet":"execute"}
        ]};
      JS
      baseline_path = File.join(directory, "baseline.yml")
      File.write(baseline_path, <<~YAML)
        version: 1
        source: test baseline
        allowlist_review:
          reviewed_at: "2026-08-09"
          missing_reason: test
          extra_reason: test
        yard_api:
          - [class, GraphQL::Schema]
          - [class_method, GraphQL::Schema.execute]
        allowed_missing: []
        allowed_extra: []
      YAML

      result = GraphQLDocs::Compatibility.new(root: directory).check(rdoc_index: index_path, baseline: baseline_path)

      _(result.fetch("unexpected_baseline_missing")).must_equal []
      _(result.fetch("unexpected_baseline_extra")).must_equal []
    end
  end
end
