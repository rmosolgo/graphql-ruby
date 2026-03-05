# frozen_string_literal: true
require "spec_helper"
require "open3"

describe "MigrateExecution" do
  it "runs as a script" do
    stderr_and_stdout, status = Open3.capture2e(%|bin/graphql-migrate-execution|)
    assert_equal 1, status.exitstatus
    assert_equal "graphql-migrate-execution requires a filename or path as a first argument, please pass one.\n", stderr_and_stdout
  end
end
