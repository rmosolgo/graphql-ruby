# frozen_string_literal: true

require "json"
require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/compatibility"

describe GraphQLDocs::Compatibility do
  it "reports duplicate and invalid entries in the RDoc index" do
    Dir.mktmpdir("graphql-docs") do |directory|
      File.write(File.join(directory, "GraphQL.html"), '<h1 id="method-c-execute">execute</h1>')
      index_path = File.join(directory, "search_data.js")
      File.write(index_path, <<~JS)
        var search_data = {"index":[
          {"full_name":"GraphQL::Schema","type":"class","path":"GraphQL.html","snippet":"Schema"},
          {"full_name":"GraphQL::Schema::execute","type":"class_method","path":"GraphQL.html#method-c-execute","snippet":"execute"},
          {"full_name":"GraphQL::Schema::execute","type":"class_method","path":"GraphQL.html#method-c-execute","snippet":"execute"},
          {"full_name":"GraphQL::Schema::multiplex","type":"class_method","path":"GraphQL.html#method-c-multiplex","snippet":"multiplex"},
          {"full_name":"GraphQL::Query","type":"class","path":"Missing.html","snippet":"Query"}
        ]};
      JS

      result = GraphQLDocs::Compatibility.new(root: directory).check(rdoc_index: index_path)

      _(result.fetch("indexed_api_entries")).must_equal 5
      _(result.fetch("duplicate_entries")).must_equal [{ "key" => ["class_method", "GraphQL::Schema::execute"], "count" => 2 }]
      _(result.fetch("invalid_entries").map { |entry| [entry.fetch("full_name"), entry.fetch("reason")] }).must_equal [
        ["GraphQL::Schema::multiplex", "missing fragment"],
        ["GraphQL::Query", "missing file"],
      ]
    end
  end
end
