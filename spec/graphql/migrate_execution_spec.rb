# frozen_string_literal: true
require "spec_helper"

describe "MigrateExecution" do
  it "runs as a script" do
    result = `bin/graphql-migrate-execution`
    assert_includes result, "graphql-migrate-execution requires a filename or path as a first argument, please pass one."
  end
end
