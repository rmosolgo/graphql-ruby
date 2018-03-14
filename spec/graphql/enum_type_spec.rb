# frozen_string_literal: true
require "spec_helper"

describe GraphQL::EnumType do
  let(:enum) { Dummy::DairyAnimalEnum }

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

  it "raises when a result value can't be coerced" do
    assert_raises(GraphQL::EnumType::UnresolvedValueError) {
      enum.coerce_isolated_result(:nonsense)
    }
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
        InvalidEnumValueTest = GraphQL::EnumType.define do
          name "InvalidEnumValueTest"

          value("SPACE IN VALUE", "Invalid enum because it contains spaces", value: 1)
        end

        # Force evaluation
        InvalidEnumValueTest.name
      }
    end
  end

  describe "invalid name" do
    it "reject names with invalid format" do
      assert_raises(GraphQL::InvalidNameError) do
        InvalidEnumNameTest = GraphQL::EnumType.define do
          name "Some::Invalid::Name"
        end

        # Force evaluation
        InvalidEnumNameTest.name
      end
    end
  end

  describe "values that are Arrays" do
    let(:schema) {
      enum = GraphQL::EnumType.define do
        name "PluralEnum"
        value 'PETS', value: ["dogs", "cats"]
        value 'FRUITS', value: ["apples", "oranges"]
        value 'PLANETS', value: ["Earth"]
      end

      query_type = GraphQL::ObjectType.define do
        name "Query"
        field :names, types[types.String] do
          argument :things, types[enum]
          resolve ->(o, a, c) {
            a[:things].reduce(&:+)
          }
        end
      end

      GraphQL::Schema.define do
        query(query_type)
      end
    }

    it "accepts them as inputs" do
      res = schema.execute("{ names(things: [PETS, PLANETS]) }")
      assert_equal ["dogs", "cats", "Earth"], res["data"]["names"]
    end
  end

  it "accepts a symbol as a variant and Ruby-land value" do
    enum = GraphQL::EnumType.define do
      name 'MessageFormat'
      value :markdown
    end

    variant = enum.values['markdown']

    assert_equal(variant.name, 'markdown')
    assert_equal(variant.value, :markdown)
  end

  it "has value description" do
    assert_equal("Animal with horns", enum.values["GOAT"].description)
  end

  describe "validate_input with bad input" do
    let(:result) { enum.validate_isolated_input("bad enum") }

    it "returns an invalid result" do
      assert(!result.valid?)
      assert_equal(
        result.problems.first['explanation'],
        "Expected \"bad enum\" to be one of: COW, DONKEY, GOAT, REINDEER, SHEEP, YAK"
      )
    end
  end

  it "accepts values array" do
    cow = GraphQL::EnumType::EnumValue.define(name: "COW")
    goat = GraphQL::EnumType::EnumValue.define(name: "GOAT")
    enum = GraphQL::EnumType.define(name: "DairyAnimal", values: [cow, goat])
    assert_equal({ "COW" => cow, "GOAT" => goat }, enum.values)
  end

  describe "#dup" do
    it "copies the values map without altering the original" do
      enum_2 = enum.dup
      enum_2.add_value(GraphQL::EnumType::EnumValue.define(name: "MUSKRAT"))
      assert_equal(6, enum.values.size)
      assert_equal(7, enum_2.values.size)
    end
  end

  describe "validates enum value name uniqueness" do
    it "raises an exception when adding a duplicate enum value name" do
      expected_message = "Enum value names must be unique. Value `COW` already exists on Enum `DairyAnimal`."

      exception = assert_raises(RuntimeError) do
        enum.add_value(GraphQL::EnumType::EnumValue.define(name: "COW"))
      end

      assert_equal(expected_message, exception.message)
    end
  end
end
