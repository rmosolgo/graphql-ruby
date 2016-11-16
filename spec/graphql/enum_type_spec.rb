require "spec_helper"

describe GraphQL::EnumType do
  let(:enum) { DairyAnimalEnum }

  it "coerces names to underlying values" do
    assert_equal("YAK", enum.coerce_input("YAK"))
    assert_equal(1, enum.coerce_input("COW"))
  end

  it "coerces invalid names to nil" do
    assert_equal(nil, enum.coerce_input("YAKKITY"))
  end

  it "coerces result values to value's value" do
    assert_equal("YAK", enum.coerce_result("YAK"))
    assert_equal("COW", enum.coerce_result(1))
    assert_equal("REINDEER", enum.coerce_result('reindeer'))
    assert_equal("DONKEY", enum.coerce_result(:donkey))
  end

  it "raises when a result value can't be coerced" do
    assert_raises(GraphQL::EnumType::UnresolvedValueError) {
      enum.coerce_result(:nonsense)
    }
  end

  describe "resolving with a warden" do
    it "gets values from the warden" do
      # OK
      assert_equal("YAK", enum.coerce_result("YAK"))
      # NOT OK
      assert_raises(GraphQL::EnumType::UnresolvedValueError) {
        enum.coerce_result("YAK", NothingWarden)
      }
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

  it "has value description" do
    assert_equal("Animal with horns", enum.values["GOAT"].description)
  end

  describe "validate_input with bad input" do
    let(:result) { DairyAnimalEnum.validate_input("bad enum", PermissiveWarden) }

    it "returns an invalid result" do
      assert(!result.valid?)
    end
  end

  it "accepts values array" do
    cow = GraphQL::EnumType::EnumValue.define(name: "COW")
    goat = GraphQL::EnumType::EnumValue.define(name: "GOAT")
    enum = GraphQL::EnumType.define(name: "DairyAnimal", values: [cow, goat])
    assert_equal({ "COW" => cow, "GOAT" => goat }, enum.values)
  end
end
