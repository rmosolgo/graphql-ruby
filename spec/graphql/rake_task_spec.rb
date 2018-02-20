# frozen_string_literal: true
require "spec_helper"

rake_task_schema_defn = <<-GRAPHQL
type Query {
  allowed(allowed: ID!, excluded: ID!): Int
  excluded(excluded: ID!): Boolean
  ignored: Float
}
GRAPHQL

RakeTaskSchema = GraphQL::Schema.from_definition(rake_task_schema_defn)

# Default task
GraphQL::RakeTask.new(schema_name: "RakeTaskSchema")
# Configured task
GraphQL::RakeTask.new(idl_outfile: "tmp/configured_schema.graphql") do |t|
  t.namespace = "graphql_custom"
  t.load_context = ->(task) { {filtered: true} }
  t.only = ->(member, ctx) { member.is_a?(GraphQL::ScalarType) || (ctx[:filtered] && ["Query", "allowed"].include?(member.name)) }
  t.load_schema = ->(task) { RakeTaskSchema }
end

describe GraphQL::RakeTask do
  describe "default settings" do
    after do
      FileUtils.rm_rf("./schema.json")
      FileUtils.rm_rf("./schema.graphql")
    end

    it "writes JSON" do
      capture_io do
        Rake::Task["graphql:schema:dump"].invoke
      end
      dumped_json = File.read("./schema.json")
      expected_json = JSON.pretty_generate(RakeTaskSchema.execute(GraphQL::Introspection::INTROSPECTION_QUERY))

      # Test that that JSON is logically equivalent, not serialized the same
      assert_equal(JSON.parse(expected_json), JSON.parse(dumped_json))

      dumped_idl = File.read("./schema.graphql")
      expected_idl = rake_task_schema_defn.chomp
      assert_equal(expected_idl, dumped_idl)
    end
  end

  describe "customized settings" do
    it "writes GraphQL" do
      capture_io do
        Rake::Task["graphql_custom:schema:idl"].invoke
      end
      dumped_idl = File.read("./tmp/configured_schema.graphql")
      expected_idl = "type Query {
  allowed(allowed: ID!): Int
}"
      assert_equal expected_idl, dumped_idl
    end
  end
end
