# frozen_string_literal: true
require "spec_helper"
require "graphql/migrate_execution"
describe "AddFuture Action" do
  it "produces new source code" do
    path = "spec/graphql/migrate_execution/fixtures/product.rb"
    source = File.read(path)
    new_source = GraphQL::MigrateExecution::AddFuture.new(nil, path, source).run
    assert_equal File.read("spec/graphql/migrate_execution/fixtures/product.migrated.rb"), new_source
  end

  it "produces new source code with dataloader usage" do
    path = "spec/graphql/migrate_execution/fixtures/dataload.rb"
    source = File.read(path)
    new_source = GraphQL::MigrateExecution::AddFuture.new(nil, path, source).run
    assert_equal File.read("spec/graphql/migrate_execution/fixtures/dataload.migrated.rb"), new_source
  end
end
