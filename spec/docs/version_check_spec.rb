# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/version_check"

describe GraphQLDocs::VersionCheck do
  it "validates a generated versioned API index" do
    Dir.mktmpdir("graphql-docs") do |directory|
      FileUtils.mkdir_p(File.join(directory, "js"))
      File.write(File.join(directory, "index.html"), "<html></html>")
      File.write(File.join(directory, "js", "search_data.js"), 'var search_data = {"index":[{"full_name":"GraphQL::Schema"}]};')
      errors = GraphQLDocs::VersionCheck.new(root: directory, version: "1.2.3").check
      _(errors).must_equal []
    end
  end

  it "rejects unresolved references in versioned output" do
    Dir.mktmpdir("graphql-docs") do |directory|
      FileUtils.mkdir_p(File.join(directory, "js"))
      File.write(File.join(directory, "index.html"), "<p>rdoc-ref:GraphQL::Schema</p>")
      File.write(File.join(directory, "js", "search_data.js"), 'var search_data = {"index":[{"full_name":"GraphQL::Schema"}]};')
      errors = GraphQLDocs::VersionCheck.new(root: directory, version: "1.2.3").check
      _(errors).must_include("versioned output contains unresolved RDoc references")
    end
  end
end
