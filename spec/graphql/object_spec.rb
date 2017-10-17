# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Object do
  describe "class attributes" do
    let(:object_class) { Jazz::Ensemble }
    it "tells type data" do
      assert_equal "Ensemble", object_class.graphql_type_name
      assert_equal "A group of musicians playing together", object_class.description
      assert_equal 1, object_class.fields.size
    end
  end

  describe ".to_graphql_type" do
    let(:obj_type) { Jazz::Ensemble.to_graphql(schema: Jazz::Schema) }
    it "returns a matching GraphQL::ObjectType" do
      assert_equal "Ensemble", obj_type.name
      assert_equal "A group of musicians playing together", obj_type.description
      assert_equal 1, obj_type.all_fields.size

      field = obj_type.all_fields.first
      assert_equal "name", field.name
      assert_equal GraphQL::STRING_TYPE.to_non_null_type, field.type
      assert_equal nil, field.description
    end
  end

  describe "in queries" do
    it "works" do
      query_str = " { ensembles { name } }"
      res = Jazz::Schema.execute(query_str)
      assert_equal [{"name" => "Bela Fleck and the Flecktones"}], res["data"]["ensembles"]
    end
  end
end
