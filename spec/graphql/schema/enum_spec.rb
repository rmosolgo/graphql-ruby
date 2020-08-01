# frozen_string_literal: true
require "spec_helper"

describe GraphQL::Schema::Enum do
  let(:enum) { Jazz::Family }

  describe ".path" do
    it "is the name" do
      assert_equal "Family", enum.path
    end
  end

  describe "type info" do
    it "tells about the definition" do
      assert_equal "Family", enum.graphql_name
      assert_equal 29, enum.description.length
      assert_equal 7, enum.values.size
    end

    it "inherits values and description" do
      new_enum = Class.new(enum) do
        value :Nonsense
        value :PERCUSSION, "new description"
      end

      # Description was inherited
      assert_equal 29, new_enum.description.length
      # values were inherited without modifying the parent
      assert_equal 7, enum.values.size
      assert_equal 8, new_enum.values.size
      perc_value = new_enum.values["PERCUSSION"]
      assert_equal "new description", perc_value.description
    end

    it "accepts a block" do
      assert_equal "Neither here nor there, really", enum.values["KEYS"].description
    end

    it "is the #owner of its values" do
      value = enum.values["STRING"]
      assert_equal enum, value.owner
    end

    it "disallows invalid names" do
      err = assert_raises GraphQL::InvalidNameError do
        Class.new(GraphQL::Schema::Enum) do
          graphql_name "Thing"
          value "IN/VALID"
        end
      end

      assert_includes err.message, "but 'IN/VALID' does not"
    end
  end

  it "uses a custom enum value class" do
    enum_type = enum.to_graphql
    value = enum_type.values["STRING"]
    assert_equal 1, value.metadata[:custom_setting]
  end

  describe ".to_graphql" do
    it "creates an EnumType" do
      enum_type = enum.to_graphql
      assert_equal "Family", enum_type.name
      assert_equal "Groups of musical instruments", enum_type.description

      string_val = enum_type.values["STRING"]
      didg_val = enum_type.values["DIDGERIDOO"]
      silence_val = enum_type.values["SILENCE"]
      assert_equal "STRING", string_val.name
      assert_equal :str, string_val.value
      assert_equal false, silence_val.value
      assert_equal "DIDGERIDOO", didg_val.name
      assert_equal "Merged into BRASS", didg_val.deprecation_reason
    end
  end

  describe "in queries" do
    it "works as return values" do
      query_str = "{ instruments { family } }"
      expected_families = ["STRING", "WOODWIND", "BRASS", "KEYS", "KEYS", "PERCUSSION"]
      result = Jazz::Schema.execute(query_str)
      assert_equal expected_families, result["data"]["instruments"].map { |i| i["family"] }
    end

    it "works as input" do
      query_str = "query($family: Family!) { instruments(family: $family) { name } }"
      expected_names = ["Piano", "Organ"]
      result = Jazz::Schema.execute(query_str, variables: { family: "KEYS" })
      assert_equal expected_names, result["data"]["instruments"].map { |i| i["name"] }
    end
  end
end
