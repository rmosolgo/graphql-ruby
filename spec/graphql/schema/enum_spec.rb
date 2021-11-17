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

  describe "legacy tests" do
    let(:enum) { Dummy::DairyAnimal }

    it "coerces names to underlying values" do
      assert_equal("YAK", enum.coerce_isolated_input("YAK"))
      assert_equal(1, enum.coerce_isolated_input("COW"))
    end

    it "coerces invalid names to nil" do
      assert_equal(nil, enum.coerce_isolated_input("YAKKITY"))
    end

    it "coerces result values to value's value" do
      assert_equal("YAK", enum.coerce_isolated_result("YAK"))
      assert_equal("COW", enum.coerce_isolated_result(1))
      assert_equal("REINDEER", enum.coerce_isolated_result('reindeer'))
      assert_equal("DONKEY", enum.coerce_isolated_result(:donkey))
    end

    it "raises a helpful error when a result value can't be coerced" do
      err = assert_raises(GraphQL::EnumType::UnresolvedValueError) {
        enum.coerce_result(:nonsense, OpenStruct.new(current_path: ["thing", 0, "name"], current_field: OpenStruct.new(path: "Thing.name")))
      }
      expected_context_message = "`Thing.name` returned `:nonsense` at `thing.0.name`, but this isn't a valid value for `DairyAnimal`. Update the field or resolver to return one of `DairyAnimal`'s values instead."
      assert_equal expected_context_message, err.message

      err2 = assert_raises(GraphQL::EnumType::UnresolvedValueError) {
        enum.coerce_isolated_result(:nonsense)
      }
      expected_isolated_message = "`:nonsense` was returned for `DairyAnimal`, but this isn't a valid value for `DairyAnimal`. Update the field or resolver to return one of `DairyAnimal`'s values instead."
      assert_equal expected_isolated_message, err2.message
    end

    describe "resolving with a warden" do
      it "gets values from the warden" do
        # OK
        assert_equal("YAK", enum.coerce_isolated_result("YAK"))
        # NOT OK
        assert_raises(GraphQL::EnumType::UnresolvedValueError) {
          enum.coerce_result("YAK", OpenStruct.new(warden: NothingWarden))
        }
      end
    end

    describe "invalid values" do
      it "rejects value names with a space" do
        assert_raises(GraphQL::InvalidNameError) {
          Class.new(GraphQL::Schema::Enum) do
            graphql_name "InvalidEnumValueTest"

            value("SPACE IN VALUE", "Invalid enum because it contains spaces", value: 1)
          end
        }
      end
    end

    describe "invalid name" do
      it "reject names with invalid format" do
        assert_raises(GraphQL::InvalidNameError) do
          Class.new(GraphQL::Schema::Enum) do
            graphql_name "Some::Invalid::Name"
          end
        end
      end
    end

    describe "values that are Arrays" do
      let(:schema) {
        Class.new(GraphQL::Schema) do
          plural = Class.new(GraphQL::Schema::Enum) do
            graphql_name "Plural"
            value 'PETS', value: ["dogs", "cats"]
            value 'FRUITS', value: ["apples", "oranges"]
            value 'PLANETS', value: ["Earth"]
          end
          query = Class.new(GraphQL::Schema::Object) do
            graphql_name "Query"
            field :names, [String], null: false do
              argument :things, [plural]
            end

            def names(things:)
              things.reduce(&:+)
            end
          end
          query(query)
        end
      }

      it "accepts them as inputs" do
        res = schema.execute("{ names(things: [PETS, PLANETS]) }")
        assert_equal ["dogs", "cats", "Earth"], res["data"]["names"]
      end
    end

    it "accepts a symbol as a value, but stringifies it" do
      enum = Class.new(GraphQL::Schema::Enum) do
        graphql_name 'MessageFormat'
        value :markdown
      end

      variant = enum.values['markdown']

      assert_equal('markdown', variant.graphql_name)
      assert_equal('markdown', variant.value)
    end

    it "has value description" do
      assert_equal("Animal with horns", enum.values["GOAT"].description)
    end

    describe "validate_input with bad input" do
      it "returns an invalid result" do
        result = enum.validate_input("bad enum", GraphQL::Query::NullContext)
        assert(!result.valid?)
        assert_equal(
          result.problems.first['explanation'],
          "Expected \"bad enum\" to be one of: COW, DONKEY, GOAT, REINDEER, SHEEP, YAK"
        )
      end
    end
  end
end
