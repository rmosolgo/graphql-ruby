# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/rdoc_ref_checker"

describe GraphQLDocs::RDocReferenceChecker do
  it "finds references that leaked into generated HTML" do
    Dir.mktmpdir("graphql-docs") do |directory|
      File.write(File.join(directory, "index.html"), "<p>rdoc-ref:GraphQL::Schema</p>")
      result = GraphQLDocs::RDocReferenceChecker.new(directory).check
      _(result).must_equal [{ "file" => "index.html", "reference" => "rdoc-ref:GraphQL::Schema" }]
    end
  end

  it "also checks the Aliki search index" do
    Dir.mktmpdir("graphql-docs") do |directory|
      FileUtils.mkdir_p(File.join(directory, "js"))
      File.write(File.join(directory, "js", "search_data.js"), "var search_data = 'rdoc-ref:GraphQL::Schema';")
      result = GraphQLDocs::RDocReferenceChecker.new(directory).check
      _([result.first["file"], result.first["reference"]]).must_equal ["js/search_data.js", "rdoc-ref:GraphQL::Schema"]
    end
  end

  it "accepts HTML without unresolved references" do
    Dir.mktmpdir("graphql-docs") do |directory|
      File.write(File.join(directory, "index.html"), "<p>GraphQL::Schema</p>")
      _(GraphQLDocs::RDocReferenceChecker.new(directory).check).must_equal []
    end
  end
end
