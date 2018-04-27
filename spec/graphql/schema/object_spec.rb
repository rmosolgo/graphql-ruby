# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Object do
  describe "class attributes" do
    let(:object_class) { Jazz::Ensemble }
    it "tells type data" do
      assert_equal "Ensemble", object_class.graphql_name
      assert_equal "A group of musicians playing together", object_class.description
      assert_equal 6, object_class.fields.size
      assert_equal 3, object_class.interfaces.size
      # Compatibility methods are delegated to the underlying BaseType
      assert object_class.respond_to?(:connection_type)
    end

    it "inherits fields and interfaces" do
      new_object_class = Class.new(object_class) do
        field :newField, String, null: true
        field :name, String, description: "The new description", null: true
      end

      # one more than the parent class
      assert_equal 7, new_object_class.fields.size
      # inherited interfaces are present
      assert_equal 3, new_object_class.interfaces.size
      # The new field is present
      assert new_object_class.fields.key?("newField")
      # The overridden field is present:
      name_field = new_object_class.fields["name"]
      assert_equal "The new description", name_field.description
    end

    it "inherits name and description" do
      # Manually assign a name since `.name` isn't populated for dynamic classes
      new_subclass_1 = Class.new(object_class) do
        graphql_name "NewSubclass"
      end
      new_subclass_2 = Class.new(new_subclass_1)
      assert_equal "NewSubclass", new_subclass_1.graphql_name
      assert_equal "NewSubclass", new_subclass_2.graphql_name
      assert_equal object_class.description, new_subclass_2.description
    end

    it "should take Ruby name (without Type suffix) as default graphql name" do
      TestingClassType = Class.new(GraphQL::Schema::Object)
      assert_equal "TestingClass", TestingClassType.graphql_name
    end

    it "raise on anonymous class without declared graphql name" do
      anonymous_class = Class.new(GraphQL::Schema::Object)
      assert_raises NotImplementedError do
        anonymous_class.graphql_name
      end
    end
  end

  describe "wrapping a Hash" do
    it "automatically looks up symbol and string keys" do
      query_str = <<-GRAPHQL
      {
        hashyEnsemble {
          musicians { name }
          formedAt
        }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      ensemble = res["data"]["hashyEnsemble"]
      assert_equal ["Jerry Garcia"], ensemble["musicians"].map { |m| m["name"] }
      assert_equal "May 5, 1965", ensemble["formedAt"]
    end

    it "works with strings and symbols" do
      query_str = <<-GRAPHQL
      {
        hashByString { falsey }
        hashBySym { falsey }
      }
      GRAPHQL
      res = Jazz::Schema.execute(query_str)
      assert_equal false, res["data"]["hashByString"]["falsey"]
      assert_equal false, res["data"]["hashBySym"]["falsey"]
    end
  end

  describe ".to_graphql_type" do
    let(:obj_type) { Jazz::Ensemble.to_graphql }
    it "returns a matching GraphQL::ObjectType" do
      assert_equal "Ensemble", obj_type.name
      assert_equal "A group of musicians playing together", obj_type.description
      assert_equal 6, obj_type.all_fields.size

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
      assert_equal ["BELA FLECK AND THE FLECKTONES", "ROBERT GLASPER EXPERIMENT"], res["data"]["ensembles"].map { |e| e["upcaseName"] }
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
      expected_ensembles = [
        {"name" => "Bela Fleck and the Flecktones"},
        {"name" => "ROBERT GLASPER Experiment"},
      ]
      assert_equal expected_ensembles, res["data"]["ensembles"]
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

      res = Jazz::Schema.execute(mutation_str, variables: { name: "Miles Davis Quartet" })
      new_id = res["data"]["addEnsemble"]["id"]

      res2 = Jazz::Schema.execute(query_str, variables: { id: new_id })
      assert_equal "Miles Davis Quartet", res2["data"]["find"]["name"]
    end

    it "initializes root wrappers once" do
      query_str = " { oid1: objectId oid2: objectId }"
      res = Jazz::Schema.execute(query_str)
      assert_equal res["data"]["oid1"], res["data"]["oid2"]
    end

    it "skips fields properly" do
      query_str = "{ find(id: \"MagicalSkipId\") { __typename } }"
      res = Jazz::Schema.execute(query_str)
      assert_equal({"data" => nil }, res.to_h)
    end
  end
end
