# frozen_string_literal: true

require "tmpdir"
require_relative "../spec_helper"
require_relative "../../tool/docs/publish_check"

describe GraphQLDocs::PublishCheck do
  it "allows a new version while preserving existing API documentation" do
    Dir.mktmpdir("graphql-docs") do |directory|
      pages = File.join(directory, "pages")
      old_file = File.join(pages, "api-doc", "1.0.0", "index.html")
      new_file = File.join(pages, "api-doc", "2.0.0", "index.html")
      FileUtils.mkdir_p(File.dirname(old_file))
      File.write(old_file, "old API")
      checker = GraphQLDocs::PublishCheck.new(pages: pages)
      snapshot = checker.snapshot
      FileUtils.mkdir_p(File.dirname(new_file))
      File.write(new_file, "new API")

      errors, changed = checker.verify(snapshot: snapshot, allowed_version: "2.0.0", expected_version: "2.0.0")
      _(errors).must_equal []
      _(changed).must_equal ["api-doc/2.0.0/index.html"]
    end
  end

  it "rejects changes to an existing version" do
    Dir.mktmpdir("graphql-docs") do |directory|
      pages = File.join(directory, "pages")
      file = File.join(pages, "api-doc", "1.0.0", "index.html")
      FileUtils.mkdir_p(File.dirname(file))
      File.write(file, "old API")
      checker = GraphQLDocs::PublishCheck.new(pages: pages)
      snapshot = checker.snapshot
      File.write(file, "modified API")

      errors, = checker.verify(snapshot: snapshot)
      _(errors).wont_be_empty
    end
  end
end
