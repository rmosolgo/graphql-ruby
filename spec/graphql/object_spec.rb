# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Object do
  describe "class attributes" do
    let(:object_class) { Jazz::Ensemble }
    it "tells type data" do
      assert_equal "Ensemble", object_class.graphql_name
      assert_equal "A group of musicians playing together", object_class.description
      assert_equal 5, object_class.fields.size
      # Compatibility methods are delegated to the underlying BaseType
      assert object_class.respond_to?(:connection_type)
    end
  end

  describe ".to_graphql_type" do
    let(:obj_type) { Jazz::Ensemble.to_graphql }
    it "returns a matching GraphQL::ObjectType" do
      assert_equal "Ensemble", obj_type.name
      assert_equal "A group of musicians playing together", obj_type.description
      assert_equal 5, obj_type.all_fields.size

      name_field = obj_type.all_fields[2]
      assert_equal "name", name_field.name
      assert_equal GraphQL::STRING_TYPE.to_non_null_type, name_field.type
      assert_equal nil, name_field.description
    end

    it "has a custom implementation" do
      assert_equal obj_type.metadata[:config], :configged
    end

    it "uses the custom field class" do
      query_str = <<-GRAPHQL
      {
        ensembles { upcaseName }
      }
      GRAPHQL

      res = Jazz::Schema.execute(query_str)
      assert_equal ["BELA FLECK AND THE FLECKTONES"], res["data"]["ensembles"].map { |e| e["upcaseName"] }
    end
  end


  describe "in queries" do
    after {
      Jazz::Models.reset
    }

    it "returns data" do
      query_str = <<-GRAPHQL
      {
        ensembles { name }
        instruments { name }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      assert_equal [{"name" => "Bela Fleck and the Flecktones"}], res["data"]["ensembles"]
      assert_equal({"name" => "Banjo"}, res["data"]["instruments"].first)
    end

    it "does mutations" do
      mutation_str = <<-GRAPHQL
      mutation AddEnsemble($name: String!) {
        addEnsemble(input: { name: $name }) {
          id
        }
      }
      GRAPHQL

      query_str = <<-GRAPHQL
      query($id: ID!) {
        find(id: $id) {
          ... on Ensemble {
            name
          }
        }
      }
      GRAPHQL

      res = Jazz::Schema.execute(mutation_str, variables: { "name" => "Miles Davis Quartet" })
      new_id = res["data"]["addEnsemble"]["id"]

      res2 = Jazz::Schema.execute(query_str, variables: { "id" => new_id })
      assert_equal "Miles Davis Quartet", res2["data"]["find"]["name"]
    end
  end
end
