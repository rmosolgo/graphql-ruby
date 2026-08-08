# frozen_string_literal: true

require "tmpdir"
require "fileutils"
require_relative "../spec_helper"
require_relative "../../tool/docs/link_checker"

describe GraphQLDocs::LinkChecker do
  it "can skip links that point to the published site's root" do
    Dir.mktmpdir("graphql-docs") do |directory|
      File.write(File.join(directory, "index.html"), '<a href="/guides/getting_started">Guide</a>')

      _(GraphQLDocs::LinkChecker.new(directory).check.size).must_equal 1
      _(GraphQLDocs::LinkChecker.new(directory, allow_root_links: true).check).must_equal []
    end
  end

  it "validates root links against a canonical published site when provided" do
    Dir.mktmpdir("graphql-docs") do |directory|
      canonical = Dir.mktmpdir("graphql-docs-canonical")
      File.write(File.join(directory, "index.html"), '<a href="/schema/definition">Guide</a>')
      FileUtils.mkdir_p(File.join(canonical, "schema"))
      File.write(File.join(canonical, "schema", "definition.html"), "<h1 id=\"guide\">Guide</h1>")

      checker = GraphQLDocs::LinkChecker.new(directory, allow_root_links: true, root_links: canonical)
      _(checker.check).must_equal []
    ensure
      FileUtils.remove_entry(canonical) if canonical && File.directory?(canonical)
    end
  end
end
