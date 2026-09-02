# frozen_string_literal: true

require "minitest/autorun"
require_relative "../../tool/docs/guide_audit"

describe GraphQLDocs::GuideAudit do
  it "classifies every guide and verifies migrated API comments" do
    errors = GraphQLDocs::GuideAudit.new(root: File.expand_path("../..", __dir__)).check
    _(errors).must_equal []
  end
end
